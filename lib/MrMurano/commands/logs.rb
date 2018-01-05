# Copyright © 2016-2018 Exosite LLC. All Rights Reserved
# License: PROPRIETARY. See LICENSE.txt.
# frozen_string_literal: true

# vim:tw=0:ts=2:sw=2:et:ai
# Unauthorized copying of this file is strictly prohibited.

#require 'cgi'
require 'json'

require 'MrMurano/hash'
require 'MrMurano/http'
require 'MrMurano/makePretty'
require 'MrMurano/verbosing'
require 'MrMurano/Logs'
require 'MrMurano/ReCommander'
require 'MrMurano/Solution'

class LogsCmd
  include MrMurano::Verbose

  LogEmitterTypes = %i[
    script
    call
    event
    config
    service
  ]

  LogSeverities = %i[
    emergency
    alert
    critical
    error
    warning
    notice
    informational
    debug
  ]

  # (lb): Ideally, we'd use +/- and not +/:, but rb-commander (or is it
  # OptionParser?) double-parses things that look like switches. E.g.,
  # `murano logs --types -call` would set options.types to ["-call"]
  # but would also set options.config to "all". Just one more reason
  # I do not think rb-commander should call itself a "complete solution".
  # (Note also we cannot use '!' instead of '-', because Bash.)
  # Another option would be to use the "no-" option, e.g., "--[no-]types",
  # but then what do you do with the sindle character '-T' option?
  ExcludeIndicator = ':'
  IncludeIndicator = '+'

  def initialize
    @filter_severity = []
    @filter_types = []
    @filter_events = []
    @filter_endpoints = []
  end

  def command_logs(cmd)
    cmd_add_logs_meta(cmd)
    # Add global solution flag: --type [application|product].
    cmd_add_solntype_pickers(cmd, exclude_all: true)
    cmd_add_logs_options(cmd)
    cmd_add_filter_options(cmd)
    cmd.action do |args, options|
      @options = options
      cmd.verify_arg_count!(args)
      logs_action
    end
  end

  def cmd_add_logs_meta(cmd)
    cmd.syntax = %(murano logs [--options])
    cmd.summary = %(Get the logs for a solution)
    cmd_add_help(cmd)
    cmd_add_examples(cmd)
  end

  def cmd_add_help(cmd)
    cmd.description = %(
      Get the logs for a solution.

      Each log record contains a number of fields, including the following.

      Severity
      ================================================================
      The severity of the log message, as defined by rsyslog standard.

        ID | Name          | Description
        -- | ------------- | -----------------------------------------
        0  | Emergency     | System is unusable
        1  | Alert         | Action must be taken immediately
        2  | Critical      | Critical conditions
        3  | Error         | Error conditions
        4  | Warning       | Warning conditions
        5  | Notice        | Normal but significant condition
        6  | Informational | Informational messages
        7  | Debug         | Debug-level messages

      Type
      ================================================================
      The type (emitter system) of the message.

        Name    | Description
        ------- | ----------------------------------------------------
        Script  | Pegasus-Engine: on User Lua “print()” function call
        Call    | Dispatcher: On service calls from Lua.
        Event   | Dispatcher: On event trigger from services
        Config  | Pegasus-API: On solution configuration change or
                |   used service deprecation warning.
        Service | Services generated & transmitted to Dispatcher.

      Message
      ================================================================
      Message can be up to 64kb containing plain text describing a log
      of the event

      Service
      ================================================================
      The service via which the event name is coming or the service of
      which the function is called.

      Event
      ================================================================
      Depending on the type:

        Event, Script => Event name
        Call          => operationId

      Tracking ID
      ================================================================
      End to end Murano processing id.
      Used to group logs together for one endpoint request.
    ).strip
  end

  def cmd_add_examples(cmd)
    cmd.example %(
      View the logs generated by device2 events
    ).strip, 'murano logs --follow --event=device2'
  end

  def cmd_add_logs_options(cmd)
    cmd.option '-f', '--follow', %(Follow logs from server)
    cmd.option '-r', '--retry', %(Always retry the connection)
  # Is localtime being honored?
    cmd.option '--[no-]localtime', %(Adjust Timestamps to be in local time)
  # Is pretty being honored?
    cmd.option '--[no-]pretty', %(Reformat JSON blobs in logs)
  # Is raw being honored?
    cmd.option '--raw', %(Do not format the log data)
  # FIXME: Implement tracking
    cmd.option '--tracking', %(Include start of the Murano Tracking ID)
    cmd.option '--tracking-full', %(Include the full Murano Tracking ID)
  #?  cmd.option '--one-line', %(Format )
  # FIXME: Implement strftime
    cmd.option '--strftime FORMAT', %(Timestamp format (default: "%Y-%M-%d %M:%S"))
  end

  def cmd_add_filter_options(cmd)
    # Common log fields.
    cmd_add_filter_option_severity(cmd)
    cmd_add_filter_option_type(cmd)
    cmd_add_filter_option_subject(cmd)
    cmd_add_filter_option_message(cmd)
    cmd_add_filter_option_service(cmd)
    cmd_add_filter_option_event(cmd)
    # Skipping: timestamp filter
    # Skipping: tracking_id filter
    # Type-specific fields in data.
    cmd_add_filter_option_endpoint(cmd)
    # Skipping: module filter
    # Skipping: elapsed time filter (i.e., could do { elapsed: { $gt: 10 } })
  end

  def cmd_add_filter_option_severity(cmd)
    cmd.option(
      '-l', '--severity [NAME|LEVEL|RANGE[,NAME|LEVEL|RANGE...]]', Array,
      %(
        Only show log entries of this severity.
        May be specified by name, value, or range, e.g., WARN, 3, 1-4.
          #{LogSeverities.map.with_index { |s, i| "#{s}(#{i})" }.join(' ')}
      ).strip
    ) do |value|
      @filter_severity.push value
    end
  end

  def cmd_add_filter_option_type(cmd)
    emitter_type_help = %(
      Filter log entries by type (emitter system) of message.
      EMITTERS is 1 or more comma-separated types:
        #{LogEmitterTypes.map(&:to_s)}
      Use a "#{IncludeIndicator}" or "#{ExcludeIndicator}" prefix to include or exclude types, respectively.
    ).strip
    cmd.option('-T EMITTERS', '--types EMITTERS', Array, emitter_type_help) do |values|
      # This seems a little roundabout, but rb-commander only
      # keeps last value unless you process them individually.
      @filter_types.push values
      values.map do |val|
        val.sub(/^[#{IncludeIndicator}#{ExcludeIndicator}]/, '')
      end
    end
  end

  def cmd_add_filter_option_subject(cmd)
    cmd.option '-S', '--subject GLOB', %(
      Filter log entries by the subject contents
    ).strip
  end

  def cmd_add_filter_option_message(cmd)
    cmd.option '-m', '--message GLOB', %(
      Filter log entries by the message contents
    ).strip
  end

  def cmd_add_filter_option_service(cmd)
    cmd.option '-s', '--service GLOB', %(
      Filter log entries by the originating service
    ).strip
  end
  
  def cmd_add_filter_option_event(cmd)
    cmd.option(
      '-e', '--event GLOB', Array,
      %(Filter log entries by the event)
    ) do |value|
      @filter_events.push value
    end
  end
  
  def cmd_add_filter_option_endpoint(cmd)
    cmd.option(
      '-e', '--endpoint ENDPOINT',
      %(Filter log entries by the endpoint (ENDPOINT is VERB:PATH or GLOB))
    ) do |value|
      @filter_endpoints.push value
    end
  end

  def logs_action
    cmd_default_logs_options
    cmd_defaults_solntype_pickers(@options, :application)
    @query = assemble_query
    verbose %(query: #{@query})
    sol = cmd_get_sol!
    logs_display(sol)
  end

  def cmd_default_logs_options
    @options.default(
      type: :application,
      follow: false,
      retry: false,
      localtime: true,
      pretty: true,
      raw: false,
      tracking: false,
      tracking_full: false,
      strftime: nil,
      severity: nil,
      types: [],
      subject: nil,
      message: nil,
      service: nil,
      event: nil,
      endpoint: nil,
    )
  end

  def cmd_get_sol!
    if @options.type == :application
      MrMurano::Application.new
    elsif @options.type == :product
      MrMurano::Product.new
    else
      error "Unknown --type specified: #{@options.type}"
      exit 1
    end
  end

  def assemble_query
    query_parts = {}
    assemble_query_severity(query_parts)
    assemble_query_types_array(query_parts)
    assemble_query_subject(query_parts)
    assemble_query_message(query_parts)
    assemble_query_service(query_parts)
    assemble_query_event(query_parts)
    assemble_query_endpoint(query_parts)
    # Assemble and return actual query string.
    assemble_query_string(query_parts)
  end

  def assemble_query_severity(query_parts)
    filter_severity = @filter_severity.flatten
    return if filter_severity.empty?
    indices = []
    filter_severity.each do |sev|
      index = sev if sev =~ /^[0-9]$/
      index = LogSeverities.find_index { |s| s.to_s =~ /^#{sev.downcase}/ } unless index
      if index
        indices.push index.to_i
      else
        parts = /^([0-9])-([0-9])$/.match(sev)
        if !parts.nil?
          start = parts[1].to_i
          finis = parts[2].to_i
          if start < finis
            more_indices = (start..finis).to_a
          else
            more_indices = (finis..start).to_a
          end
          indices += more_indices
        else
          warning "Invalid severity: #{sev}"
          exit 1
        end
      end
    end
    query_parts['severity'] = { '$in': indices }
  end

  def assemble_query_types_array(query_parts)
    assemble_in_or_nin_query(query_parts, 'type', @filter_types.flatten) do |type|
      index = LogEmitterTypes.find_index { |s| s.to_s =~ /^#{type.downcase}/ }
      if index
        LogEmitterTypes[index].to_s.capitalize
      else
        warning "Invalid emitter type: #{type}"
        exit 1
      end
    end
  end

  def assemble_query_subject(query_parts)
    assemble_string_search_one(query_parts, 'subject', @options.subject)
  end

  def assemble_query_message(query_parts)
    assemble_string_search_one(query_parts, 'message', @options.message)
  end

  def assemble_query_service(query_parts)
    assemble_string_search_one(query_parts, 'service', @options.service)
  end

  def assemble_query_event(query_parts)
    assemble_string_search_many(query_parts, 'event', @filter_events)
  end

  def assemble_query_endpoint(query_parts)
    assemble_string_search_many(query_parts, 'endpoint', @filter_endpoints)
  end

  def assemble_string_search_one(query_parts, field, value)
    return if value.to_s.empty?
    # FIXME (lb): Platform does not seem to support $regex, which
    # seems like a better choice than strict equality. But for now
    # we have to do $eq to at least make it sort of work.
    # Ask platform team how to make this work:
    #   query_parts[field] = { '$regex': "/#{value}/i" }
    # I also tried these:
    #    query_parts[field] = { '$regex': "/#{value}/" }
    #    query_parts[field] = { '$regex': "/.*#{value}.*/" }
    # For now, this:
    query_parts[field] = { '$eq': value }
  end

  def assemble_string_search_many(query_parts, field, arr_of_arrs)
    terms = arr_of_arrs.flatten
    return if terms.empty?
    if terms.length == 1
      assemble_string_search_one(query_parts, field, terms[0])
    else
      assemble_in_or_nin_query(query_parts, field, terms)
    end
  end

  def assemble_in_or_nin_query(query_parts, field, terms, &block)
    return if terms.empty?
    exclude = term_indicates_exclude?(terms[0])
    resolved_terms = []
    terms.each do |term|
      process_query_term(term, resolved_terms, exclude, field, terms, &block)
    end
    return if resolved_terms.empty?
    if !exclude
      operator = '$in'
    else
      operator = '$nin'
    end
#    query_parts.push(
#      %(#{field}: { #{operator}: [ #{resolved_terms.map{ |x| %("#{x}") }.join(',')} ] })
#    )
    query_parts[field] = { "#{operator}": resolved_terms }
  end

  def term_indicates_exclude?(term)
    if term.start_with? ExcludeIndicator
      true
    else
      false
    end
  end

  def process_query_term(term, resolved_terms, exclude, field, terms, &block)
    verify_term_plus_minux_prefix!(term, exclude, field, terms)
    term = term.sub(/^[#{IncludeIndicator}#{ExcludeIndicator}]/, '')
    term = yield term if block_given?
    resolved_terms.push term
  end

  def verify_term_plus_minux_prefix!(term, exclude, field, terms)
    return unless term =~ /^[#{IncludeIndicator}#{ExcludeIndicator}]/
    return unless (
      (!exclude && term.start_with?(ExcludeIndicator)) ||
      (exclude && term.start_with?(IncludeIndicator))
    )
    warning(
      %(You cannot mix + and ! for "#{field}": #{terms.join(',')})
    )
    exit 1
  end

  def assemble_query_string(query_parts)
    if query_parts.empty?
      ''
    else
#      %(?query={ #{query_parts.join(', ')} })
# FIXME: URI scrub??
      query_parts.to_json
#      %(?query=#{CGI.escape(query_parts.to_json)})
    end
  end

  def logs_display(sol)
    if !@options.follow
      logs_once(sol)
    else
      logs_follow(sol)
    end
  end

  def logs_once(sol)
    query = @query.empty? && '' || "?query=#{@query}"
    ret = sol.get("/logs#{@query}")
    if ret.is_a?(Hash) && ret.key?(:items)
      ret[:items].reverse.each do |line|
        if @options.raw
          puts line
        else
          puts MrMurano::Pretties.MakePrettyLogsV1(line, @options)
        end
      end
    else
      sol.error "Could not get logs: #{ret}"
      exit 1
    end
  end

  # LATER/2017-12-14 (landonb): Show logs from all associated solutions.
  #   We'll have to wire all the WebSockets from within the EM.run block.
  def logs_follow(sol)
    formatter = get_formatter
    keep_running = true
    while keep_running
      keep_running = @options.retry
      logs = MrMurano::Logs::Follow.new(@query)
      logs.run_event_loop(sol) do |line|
        log_entry = parse_logs_line(line)
        if log_entry[:statusCode] == 400
          warning "Query error: #{log_entry}"
        else
          formatter.call(log_entry) unless log_entry.nil?
        end
      end
    end
  end

  def parse_logs_line(line)
    log_entry = JSON.parse(line)
    elevate_hash(log_entry)
  rescue StandardError => err
    warning "Not JSON: #{err} / #{line}"
    nil
  end

  def get_formatter
    if @options.raw
      method(:print_raw)
    else
      method(:print_pretty)
    end
  end

  def print_raw(line)
    puts line
  end

  def print_pretty(line)
    puts MrMurano::Pretties.MakePrettyLogsV2(line, @options)
  rescue StandardError => err
    error "Failed to parse log: #{err} / #{line}"
    raise
  end
end

def wire_cmd_logs
  logs_cmd = LogsCmd.new
  command(:logs) { |cmd|
    logs_cmd.command_logs(cmd)
  }
  alias_command 'logs application', 'logs', '--type', 'application'
  alias_command 'logs product', 'logs', '--type', 'product'
  alias_command 'application logs', 'logs', '--type', 'application'
  alias_command 'product logs', 'logs', '--type', 'product'
end

wire_cmd_logs

