commander = require 'commander'
shelljs = require 'shelljs'
chalk = require 'chalk'
fs = require 'fs'
_ = require 'lodash'

pkg = (path, cb) ->
  fs.readFile path, (err, data) ->
    if err
      return cb err
    try
      json = JSON.parse data.toString()
      if not json.mean?
        return cb err
      cb null, json
    catch err
      return cb err

commander.description 'create new project or plugin with provided dirname'
commander.usage '[options] <type> <dirname>'
commander.option '-b, --branch <branch>', 'specify git branch'
commander.option '-p, --buildpack <buildpack>', 'specify buildpack'
commander.option '-g, --git', 'close using git instead of https'
commander.option '-r, --repository <repository>', 'specify specific repository to install'
commander.parse process.argv

if commander.args.length < 2
  console.log()
  console.log chalk.yellow('  Please specify type and directory name')
  commander.help()
  process.exit 0
else
  type = commander.args[0]
  if type not in ['project', 'plugin']
    console.log()
    console.log chalk.red('  Invalid type specified, valid types are project and plugin')
    commander.help()
    process.exit 0
  name = commander.args[1]

if not commander.branch? then commander.branch = 'master'

if not shelljs.which 'git'
  console.log chalk.red('  Prerequisite not installed: git')
  process.exit 0

if not commander.buildpack
  commander.buildpack = 'coffee'

if commander.git?
  source = "git@github.com:meanstackjs/meanstack-#{type}-#{commander.buildpack}.git"
else
  source = "https://github.com/meanstackjs/meanstack-#{type}-#{commander.buildpack}.git"

if commander.repository?
  source = commander.repository

source = "#{commander.branch} #{source} #{name}"

console.log()
console.log chalk.green("  Cloning branch #{commander.branch} into #{name}")

if type is 'plugin'
  if fs.existsSync './package.json'
    f = JSON.parse fs.readFileSync('./package.json').toString()
    if not f.mean?
      console.log()
      console.log chalk.red('  Invalid MEAN Stack project root directory')
      console.log()
      process.exit 0
  else
    console.log()
    console.log chalk.red('  Invalid MEAN Stack project root directory')
    console.log()
    process.exit 0

  if not fs.existsSync 'plugins'
    fs.mkdirSync 'plugins'
  shelljs.cd 'plugins'

shelljs.exec "git clone -b #{source}", (err) ->
  if err
    console.log()
    console.log chalk.red '  Error: git clone failed'
    console.log()
    return

  pkg "./#{name}/package.json", (err, data) ->
    if err
      console.log chalk.yellow('Something went wrong. Try again or use --git flag')
      console.log chalk.yellow('If the problem persists see past issues at https://github.com/meanstackjs/meanstack/issues')
      console.log chalk.yellow('Or open a new issue here https://github.com/meanstackjs/meanstack/issues/new')
      process.exit 0
    console.log()
    console.log chalk.green("  Version #{data.version} cloned")
    console.log()
    shelljs.cd name
    shelljs.exec 'git remote remove origin', (err) ->
      if err
        console.log '  Unable to remove git remote origin'
        console.log()
    if type is 'project'
      console.log '    Install dependencies:'
      console.log "      cd #{name} && npm install"
      console.log()
      console.log '    Run app in development mode (development with watcher enabled):'
      console.log '      grunt develop'
      console.log '    Run app in preview mode (production):'
      console.log '      grunt preview'
      console.log '    Start app in production mode (production):'
      console.log '      node server.js'
    else if type is 'plugin'
      console.log '    Modifications before installation:'
      console.log "    Change name in package.json to match your plugin name."
      console.log "    Change angular plugin name."
      console.log()
      console.log '    Install dependencies:'
      console.log "      cd plugins/#{name} && npm install"
      console.log()
      console.log '    Include plugin:'
      console.log "    Add vhost for your plugin if you need server side logic."
      console.log "    Register plugin assets in assets.json (assets are located in public/plugins/#{name})."
      console.log()
      console.log '    Run app in development mode (development with watcher enabled):'
      console.log '      grunt develop'
      console.log()
      console.log '    Test:'
      console.log '    Access /#/plugin in your browser to test if angular modules are working.'
      console.log '    Access /plugin/ in your browser to test if plugin routing is working.'
    console.log()
    console.log '    Documentation is available at http://meanstackjs.com'

console.log()
