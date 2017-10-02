# Last Modified: 2017.10.02 /coding: utf-8
# frozen_string_literal: true

# Copyright © 2016-2017 Exosite LLC.
# License: MIT. See LICENSE.txt.
#  vim:tw=0:ts=2:sw=2:et:ai

require 'MrMurano/Account'
require 'MrMurano/Config'
require 'MrMurano/ReCommander'

command 'login' do |c|
  c.syntax = %(murano login [--options] [<username>])
  c.summary = %(Log into Murano)
  c.description = %(
Log into Murano.

If you are having trouble logging in, try deleting the saved password first:

  murano password delete <username>

You might also need to unset the password environment variable:

  MURANO_PASSWORD=

You can also try the logout command:

  murano logout
  ).strip

  c.example %(
    Login interactively. You'll be asked for your username (email) and password.
  ).strip, %(murano login)

  c.example %(
    Or, specify the account to use to logon.
  ).strip, %(murano login <username>)

  c.example %(
    If you want to include the password, use an environment variable.
  ).strip, %(MURANO_PASSWORD=xyz murano login <username>)

  c.example %(
    Developers can specify a different host than might be configured globally.
  ).strip, %(murano login <username> --host <address>)

  c.option '--show-token', %(Shows the API token)
  c.option '--host HOST', %(Same as `murano login -c net.host="a.b.c"`)

  c.project_not_required = true
  c.prompt_if_logged_off = true

# FIXME: Clean UP:
  c.action do |args, options|
    c.verify_arg_count!(args, 1)
    $cfg['user.name'] = args[0] unless args[0].nil?
    $cfg.set_net_host(options.host, :internal) unless options.host.nil?
    MrMurano::Verbose.verbose %(
      Checking #{$cfg['user.name']} on #{$cfg['net.protocol']}://#{$cfg['net.host']}
    ).strip
    tok = MrMurano::Account.instance.token
    say tok if options.show_token
    # Save user.name and net.protocol/net.host to project file if successful.
    # (This makes it easier to jump between projects on different environments.]
# THINK ON THIS:
# - User might want to be logging on to :user config -- that's where this is saved, right?
# - User might be wanting to use :env or :specified and avoid creating/editing project config
#     IF THAT'S THE CASE: you should always check in one of these in use and never write to
#                           :project unless config command and user is telling you to??
# hrmmmmm... i think this could work...
# but this code would need to be shared with init command...
# and what about, say, murano solution create in empty directory,
#   i think that works: we would have to maybe save to :project file there, too...
#
    unless tok.to_s.empty?
      [
        'user.name',
        'net.protocol',
        'net.host',
      ].each { |key| $cfg.set(key, $cfg[key], :project) }
    end
  end
end

command 'logout' do |c|
  c.syntax = %(murano logout)
  c.summary = %(Log out of Murano)


# FIXME: This is wrong: The unset only happens if user.name and net.host match...
# and in any case, I think this should be more about clearing the password...
#
# I THINK LOGOUT should only delete username from "active"/"exposed" config
# SHOULD WE WARN/CARE if :specified and :env? Which one wins? Which one is "exposed"?
#
# FIXME LOGOUT to complain when things do not happen,
# e.g., net.host/user.name not found in password file
# e.g., already cleared from/not found in config (and which config file)
#
# MAYBE: use the --user/--project/--env/--specified options from config.rb??
# 
  c.description = %(
Log out of Murano.

This command will unset the user.name in the user config, and
it will remove that user's password from the password file.

Essentially, this command is the same as:

  murano password delete <username>
  murano password delete <username>/twofactor

Include the --user option to also clear the username, e.g.,

  murano config --unset user.name --user
  murano config --unset user.name --project
  ).strip

  c.project_not_required = true

  c.option '--token', 'Remove only the two-factor token'
# FIXME: What if user specified another config?
#   --configfile :specified / MURANO_CONFIGFILE :env / and :project and :user
  c.option '--username', 'Also remove the user.name config values'

  c.action do |args, options|
    c.verify_arg_count!(args)
    MrMurano::Account.instance.logout(options.token)
  end
end

