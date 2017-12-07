# Copyright © 2016-2017 Exosite LLC. All Rights Reserved
# License: PROPRIETARY. See LICENSE.txt.
# frozen_string_literal: true

# vim:tw=0:ts=2:sw=2:et:ai
# Unauthorized copying of this file is strictly prohibited.

require 'MrMurano/makePretty'
require 'MrMurano/ReCommander'
require 'MrMurano/Solution'

command :logs do |c|
  c.syntax = %(murano logs [--options])
  c.summary = %(Get the logs for a solution)
  c.description = %(
Get the logs for a solution.
  ).strip

  # Add flag: --type [application|product].
  cmd_add_solntype_pickers(c, exclude_all: true)

  c.option '-f', '--follow', %(Follow logs from server)
  c.option '--[no-]pretty', %(Reformat JSON blobs in logs.)
  c.option '--[no-]localtime', %(Adjust Timestamps to be in local time)
  c.option '--raw', %(Don't do any formating of the log data)
  # FIXME/2017-06-23: It'd be nice to allow :all
  #   But then we'd have to interleave output somehow with --follow,
  #   maybe using separate threads?

  c.action do |args, options|
    c.verify_arg_count!(args)
    options.default(pretty: true, localtime: true, raw: false, type: :application)
    cmd_defaults_solntype_pickers(options, :application)

    if options.type == :application
      sol = MrMurano::Application.new
    elsif options.type == :product
      sol = MrMurano::Product.new
    else
      MrMurano::Verbose.error "Unknown --type specified: #{options.type}"
      exit 1
    end

    if options.follow
      # Open a lasting connection and continually feed makePretty().
      begin
        sol.get('/logs?polling=true') do |request, http|
          request['Accept-Encoding'] = 'None'
          http.request(request) do |response|
            remainder = ''
            response.read_body do |chunk|
              chunk = remainder + chunk unless remainder.empty?

              # For all complete JSON blobs, make them pretty.
              chunk.gsub!(/\{(?>[^}{]+|\g<0>)*\}/m) do |m|
                if options.raw
                  puts m
                else
                  begin
                    js = JSON.parse(
                      m,
                      allow_nan: true,
                      symbolize_names: true,
                      create_additions: false,
                    )
                    puts MrMurano::Pretties.makePretty(js, options)
                  rescue StandardError
                    sol.error '=== JSON parse error, showing raw instead ==='
                    puts m
                  end
                end
                '' #remove (we're kinda abusing gsub here.)
              end

              # Is there an incomplete one?
              chunk.match(/(\{.*$)/m) do |mat|
                remainder = mat[1]
              end
            end
          end
        end
      # rubocop:disable Lint/HandleExceptions: Do not suppress exceptions.
      rescue Interrupt => _
      end

    else
      ret = sol.get('/logs')

      if ret.is_a?(Hash) && ret.key?(:items)
        ret[:items].reverse.each do |line|
          if options.raw
            puts line
          else
            puts MrMurano::Pretties.makePretty(line, options)
          end
        end
      else
        sol.error "Couldn't get logs: #{ret}"
        # 2017-06-23: Shouldn't this be exit? What're we breaking out of?
        break
      end
    end
  end
end
alias_command 'logs application', 'logs', '--type', 'application'
alias_command 'logs product', 'logs', '--type', 'product'
alias_command 'application logs', 'logs', '--type', 'application'
alias_command 'product logs', 'logs', '--type', 'product'

