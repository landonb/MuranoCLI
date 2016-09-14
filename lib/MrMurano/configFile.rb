require 'pathname'
require 'inifile'
require 'pp'

module MrMurano
  class Config
    #
    #  internal    transient this-run-only things (also -c options)
    #  specified   from --configfile
    #  private     .mrmuranorc.private at project dir (for things you don't want to commit)
    #  project     .mrmuranorc at project dir
    #  user        .mrmuranorc at $HOME
    #  system      .mrmuranorc at /etc
    #  defaults    Internal hardcoded defaults
    #
    ConfigFile = Struct.new(:kind, :path, :data) do
      def load()
        return if kind == :internal
        return if kind == :defaults
        self[:path] = Pathname.new(path) unless path.kind_of? Pathname
        self[:data] = IniFile.new(:filename=>path.to_s) if self[:data].nil?
        self[:data].restore
      end

      def write()
        return if kind == :internal
        return if kind == :defaults
        self[:path] = Pathname.new(path) unless path.kind_of? Pathname
        self[:data] = IniFile.new(:filename=>path.to_s) if self[:data].nil?
        self[:data].save
        path.chmod(0600)
      end
    end

    attr :paths

    CFG_SCOPES=%w{internal specified project private user system defaults}.map{|i| i.to_sym}.freeze
    CFG_FILE_NAME = '.mrmuranorc'.freeze
    CFG_PRVT_NAME = '.mrmuranorc.private'.freeze
    CFG_DIR_NAME = '.mrmurano'.freeze
    CFG_ALTRC_NAME = '.mrmurano/config'.freeze
    CFG_SYS_NAME = '/etc/mrmuranorc'.freeze

    def initialize
      @paths = []
      @paths << ConfigFile.new(:internal, nil, IniFile.new())
      # :specified --configfile FILE goes here. (see load_specific)
      prjfile = findProjectDir()
      unless prjfile.nil? then
        @paths << ConfigFile.new(:private, prjfile + CFG_PRVT_NAME)
        @paths << ConfigFile.new(:project, prjfile + CFG_FILE_NAME)
      end
      @paths << ConfigFile.new(:user, Pathname.new(Dir.home) + CFG_FILE_NAME)
      @paths << ConfigFile.new(:system, Pathname.new(CFG_SYS_NAME))
      @paths << ConfigFile.new(:defaults, nil, IniFile.new())


      set('tool.verbose', false, :defaults)
      set('tool.dry', false, :defaults)

      set('net.host', 'bizapi.hosted.exosite.io', :defaults)

      set('location.base', prjfile, :defaults) unless prjfile.nil?
      set('location.files', 'files', :defaults)
      set('location.endpoints', 'endpoints', :defaults)
      set('location.modules', 'modules', :defaults)
      set('location.eventhandlers', 'eventhandlers', :defaults)
      set('location.roles', 'roles.yaml', :defaults)
      set('location.users', 'users.yaml', :defaults)

      set('files.default_page', 'index.html', :defaults)

      set('eventhandler.skiplist', 'websocket webservice device.service_call', :defaults)

      set('diff.cmd', 'diff -u', :defaults)
    end

    ## Find the root of this project Directory.
    #
    # The Project dir is the directory between PWD and HOME that has one of (in
    # order of preference):
    # - .mrmuranorc
    # - .mrmuranorc.private
    # - .mrmurano/config
    # - .mrmurano/
    # - .git/
    def findProjectDir()
      result=nil
      fileNames=[CFG_FILE_NAME, CFG_PRVT_NAME, CFG_ALTRC_NAME]
      dirNames=[CFG_DIR_NAME, '.git']
      home = Pathname.new(Dir.home)
      pwd = Pathname.new(Dir.pwd)
      return nil if home == pwd
      pwd.dirname.ascend do |i|
        break unless result.nil?
        break if i == home
        fileNames.each do |f|
          if (i + f).exist? then
            result = i
          end
        end
        dirNames.each do |f|
          if (i + f).directory? then
            result = i
          end
        end
      end
      # if nothing found, assume it will live in pwd.
      result = Pathname.new(Dir.pwd) if result.nil?
      return result
    end

    def load()
      # - read/write config file in [Project, User, System] (all are optional)
      @paths.each { |cfg| cfg.load }
    end

    def load_specific(file)
      spc = ConfigFile.new(:specified, Pathname.new(file))
      spc.load
      @paths.insert(1, spc)
    end

    # key is <section>.<key>
    def get(key, scope=CFG_SCOPES)
      scope = [scope] unless scope.kind_of? Array
      paths = @paths.select{|p| scope.include? p.kind}

      section, ikey = key.split('.')
      paths.each do |path|
        if path.data.has_section?(section) then
          sec = path.data[section]
          return sec if ikey.nil?
          if sec.has_key?(ikey) then
            return sec[ikey]
          end
        end
      end
      return nil
    end

    def dump()
      # have a fake, merge all into it, then dump it.
      base = IniFile.new()
      @paths.reverse.each do |ini|
        base.merge! ini.data
      end
      base.to_s
    end

    def set(key, value, scope=:project)
      section, ikey = key.split('.', 2)
      raise "Invalid key" if section.nil?
      if not section.nil? and ikey.nil? then
        # If key isn't dotted, then assume the tool section.
        ikey = section
        section = 'tool'
      end

      paths = @paths.select{|p| scope == p.kind}
      raise "Unknown scope" if paths.empty?
      cfg = paths.first
      data = cfg.data
      tomod = data[section]
      tomod[ikey] = value unless value.nil?
      tomod.delete(ikey) if value.nil?
      data[section] = tomod
      cfg.write
    end

    # key is <section>.<key>
    def [](key)
      get(key)
    end

    # For setting internal, this-run-only values
    def []=(key, value)
      set(key, value, :internal)
    end

  end

  ##
  # IF none of -same, then -same; else just the ones listed.
  def self.checkSAME(opt)
    unless opt.files or opt.endpoints or opt.modules or
        opt.eventhandlers or opt.roles or opt.users then
      opt.files = true
      opt.endpoints = true
      opt.modules = true
      opt.eventhandlers = true
    end
    if opt.all then
      opt.files = true
      opt.endpoints = true
      opt.modules = true
      opt.eventhandlers = true
      opt.roles = true
      opt.users = true
    end
  end
end

command :config do |c|
  c.syntax = %{mr config [options] <key> [<new value>]}
  c.summary = %{Get and set options}
  c.description = %{
  You can get, set, or query config options with this command.  All config
  options are in a 'section.key' format.  There is also a layer of scopes
  that the keys can be saved in.
  }

  c.example %{See what the current combined config is}, 'mr config --dump'
  c.example %{Query a value}, 'mr config solution.id'
  c.example %{Set a new value; writing to the project config file}, 'mr config solution.id XXXXXXXX'
  c.example %{Set a new value; writing to the private config file}, 'mr config --private solution.id XXXXXXXX'
  c.example %{Set a new value; writing to the user config file}, 'mr config --user user.name my@email.address'
  c.example %{Unset a value in a configfile. (lower scopes will become visible if set)},
    'mr config diff.cmd --unset'


  c.option '--system', 'Use only the system config file. (/etc/mrmuranorc)'
  c.option '--user', 'Use only the config file in $HOME (.mrmuranorc)'
  c.option '--project', 'Use only the config file in the project (.mrmuranorc)'
  c.option '--private', 'Use only the private config file in the project (.mrmuranorc.private)'
  c.option '--specified', 'Use only the config file from the --config option.'

  c.option '--unset', 'Remove key from config file.'
  c.option '--dump', 'Dump the current combined view of the config'

  c.action do |args, options|

    if options.dump then
      puts $cfg.dump()
    elsif args.count == 0 then
      say_error "Need a config key"
    elsif args.count == 1 and not options.unset then
      options.defaults :system=>false, :user=>false, :project=>false,
        :specified=>false, :private=>false

      # For read, if no scopes, than all. Otherwise just those specified
      scopes = []
      scopes << :system if options.system
      scopes << :user if options.user
      scopes << :project if options.project
      scopes << :private if options.private
      scopes << :specified if options.specified
      scopes = MrMurano::Config::CFG_SCOPES if scopes.empty?

      say $cfg.get(args[0], scopes)
    else

      options.defaults :system=>false, :user=>false, :project=>true,
        :specified=>false, :private=>false
      # For write, if scope is specified, only write to that scope.
      scope = :project
      scope = :system if options.system
      scope = :user if options.user
      scope = :project if options.project
      scope = :private if options.private
      scope = :specified if options.specified

      args[1] = nil if options.unset
      $cfg.set(args[0], args[1], scope)
    end
  end

end

command 'config import' do |c|
  c.syntax = %{mr config import}
  c.summary = %{Import data from a Solutionfile.json and .Solutionfile.secret}
  c.description = %{
  }

  c.action do |args, options|
    solfile = ($cfg['location.base'] + 'Solutionfile.json')
    solsecret = ($cfg['location.base'] + '.Solutionfile.secret')

    if solfile.exist? then
      # Is in JSON, which as a subset of YAML, so use YAML parser
      solfile.open do |io|
        sf = YAML.load(io)
        $cfg.set('location.files', sf['assets']) if sf.has_key? 'assets'
        $cfg.set('location.files', sf['file_dir']) if sf.has_key? 'file_dir'
        $cfg.set('files.default_page', sf['default_page']) if sf.has_key? 'default_page'

        if sf.has_key?('modules') and sf['modules'].kind_of?(Hash) then
          # How to import if not in common sub-directory? warn that user will need
          # manual work.


          # If all modules are in 
          # ./moddir(/subdir)?/file

        end

        if sf.has_key?('event_handler') then
          # How to import if not in common sub-directory?
        end
      end
    end

    if solsecret.exist? then
      # Is in JSON, which as a subset of YAML, so use YAML parser
      solsecret.open do |io|
        ss = YAML.load(io)

        pff = Pathname.new(ENV['HOME']) + '.mrmurano/passwords'
        pwd = MrMurano::Passwords.new(pff)
        pwd.load
        ps = pwd.get($cfg['net.host'], ss['email'])
        if ps.nil? then
          pwd.set($cfg['net.host'], ss['email'], ss['password'])
          pwd.save
        elsif ps != ss['password'] then
          y = ask("A different password for this account already exists. Overwrite? N/y")
          if y =~ /^y/i then
            pwd.set($cfg['net.host'], ss['email'], ss['password'])
            pwd.save
          end
        else
          # already set, nothing to do.
        end

        $cfg.set('solution.id', ss['solution_id']) if ss.has_key? 'solution_id'
        $cfg.set('solution.id', ss['product_id']) if ss.has_key? 'product_id'
      end
    end
  end

end

#  vim: set ai et sw=2 ts=2 :
