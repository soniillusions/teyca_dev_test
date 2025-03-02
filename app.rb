require 'sinatra'
require 'sequel'
require 'require_all'

DB = Sequel.sqlite('db/test.db')

set :database, { adapter: 'sqlite3', database: 'db/test.db' }

require_all 'models'