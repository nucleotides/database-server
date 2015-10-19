require 'pg'

PARAMS = {
  user:      "POSTGRES_USER",
  password:  "POSTGRES_PASSWORD",
  host:      "POSTGRES_HOST",
  dbname:    "POSTGRES_NAME"
}

def db
  params = Hash[PARAMS.map do |k,v|
    [k, ENV[v]]
  end]
  params[:port] = params[:host].split(':').last
  params[:host] = params[:host].split(':').first.gsub("//","")

  @conn ||= PG.connect(params)
  @conn
end

Given(/^an empty database without any tables$/) do
  db.exec("drop schema public cascade;")
  db.exec("create schema public;")
end
