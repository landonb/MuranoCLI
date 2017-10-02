# Last Modified: 2017.09.21 /coding: utf-8
# frozen_string_literal: true

# Copyright © 2016-2017 Exosite LLC.
# License: MIT. See LICENSE.txt.
#  vim:tw=0:ts=2:sw=2:et:ai

require 'MrMurano/Account'
require 'MrMurano/Config'
require 'MrMurano/ReCommander'

command 'login' do |c|
  c.syntax = %(murano login)
  c.summary = %(Log into Murano)
  c.description = %(
Log into Murano.

If you are having trouble logging in, try deleting the saved password first:

  murano password delete <username>
  ).strip
  c.option '--show-token', %(Shows the API token)
  c.project_not_required = true
  c.prompt_if_logged_off = true

# FIXME: Clean UP:
  c.action do |args, options|
    c.verify_arg_count!(args)
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
  murano config --unset --user user.name
  ).strip
  c.project_not_required = true

  c.option '--token', 'Remove just the two-factor token'

  c.action do |args, options|
    c.verify_arg_count!(args)
    MrMurano::Account.instance.logout(options.token)
  end
end

