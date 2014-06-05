commander = require 'commander'
chalk = require 'chalk'
_ = require 'lodash'

commander.command 'init <dirname> [options]', 'init new project with provided dirname'
commander.parse process.argv

if commander.args.length < 1
  commander.help()

commands = commander.commands.map (command) ->
  command._name

if not _.contains commands, commander.args[0]
  console.log()
  console.log chalk.red("  Command #{commander.rawArgs[2]} is not valid")
  commander.help()
  console.log()
  process.exit 0
