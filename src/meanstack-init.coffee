commander = require 'commander'
shelljs = require 'shelljs'
chalk = require 'chalk'
fs = require 'fs'
path = require 'path'
_ = require 'lodash'

init = (dirname, name, minimal, cb) ->
  file = path.resolve(path.join process.cwd(), dirname, 'package.json')
  fs.readFile file, (err, data) ->
    if err
      return cb err
    try
      json = JSON.parse data.toString()
      json.name = name

      if minimal
        delete json.dependencies['express-session']
        delete json.dependencies['express-validator']
        delete json.dependencies['connect-mongo']
        delete json.dependencies['connect-flash']
        delete json.dependencies['compression']
        delete json.dependencies['body-parser']
        delete json.dependencies['cookie-parser']
        delete json.dependencies['method-override']
        delete json.dependencies['serve-favicon']
        delete json.dependencies['view-helpers']
        delete json.dependencies['errorhandler']

      fs.writeFile file, JSON.stringify(json, null, 2), (err) ->
        if err
          return cb err
        file = path.resolve(path.join process.cwd(), dirname, '.bowerrc')
        fs.readFile file, (err, data) ->
          if err
            return cb err

          bower = JSON.parse data.toString()
          bower.directory = "public/#{name}/vendor/"

          fs.writeFile file, JSON.stringify(bower, null, 2), (err) ->
            if err
              return cb err
            cb null, json
    catch err
      return cb err

commander.description 'init new project with provided dirname'
commander.usage '[options] <dirname>'
commander.option '-n, --name <name>', 'specify project name'
commander.option '-m, --minimal', 'init with minimal dependencies'
commander.option '-b, --branch <branch>', 'specify git branch'
commander.option '-p, --buildpack <buildpack>', 'specify buildpack'
commander.option '-g, --git', 'close using git instead of https'
commander.option '-r, --repository <repository>', 'specify specific repository to install'
commander.parse process.argv

if commander.args.length < 1
  console.log()
  console.log chalk.yellow('  Please specify directory name')
  commander.help()
  process.exit 0
else
  dirname = commander.args[0]

if not commander.name?
  name = dirname
else
  name = commander.name

if not commander.minimal?
  minimal = false
else
  minimal = true

if not commander.branch? then commander.branch = 'master'

if not shelljs.which 'git'
  console.log chalk.red('Prerequisite not installed: git')
  console.log()
  process.exit 0

if not commander.buildpack
  commander.buildpack = 'coffee'

if commander.git?
  source = "git@github.com:meanstackjs/meanstack-skeleton-#{commander.buildpack}.git"
else
  source = "https://github.com/meanstackjs/meanstack-skeleton-#{commander.buildpack}.git"

if commander.repository?
  source = commander.repository

source = "#{commander.branch} #{source} #{dirname}"

console.log()
console.log chalk.green("Cloning branch #{commander.branch} into #{dirname}")

shelljs.exec "git clone -b #{source}", (err) ->
  if err
    console.log()
    console.log chalk.red 'Error: git clone failed'
    console.log()
    return

  init dirname, name, minimal, (err, data) ->
    if err
      console.log chalk.yellow('Something went wrong. Try again or use --git flag')
      console.log chalk.yellow('If the problem persists see past issues at https://github.com/meanstackjs/meanstack/issues')
      console.log chalk.yellow('Or open a new issue here https://github.com/meanstackjs/meanstack/issues/new')
      console.log()
      process.exit 0
    console.log()
    console.log chalk.green("Version #{data.version} cloned")
    console.log()
    shelljs.cd dirname
    shelljs.exec 'git remote remove origin', (err) ->
      if err
        console.log 'Unable to remove git remote origin'
        console.log()
    console.log 'Install dependencies:'
    console.log "  cd #{dirname} && npm install"
    console.log()
    console.log 'Run app in development mode (development environment):'
    console.log '  grunt develop'
    console.log 'Run app in debugging mode (development environment):'
    console.log '  grunt debug'
    console.log 'Run app in preview mode (production environment):'
    console.log '  grunt preview'
    console.log 'Start app in production mode (production environment):'
    console.log '  node server.js'
    console.log()

console.log()
