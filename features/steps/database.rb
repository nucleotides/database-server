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

Then(/^the table "(.*?)" should have the entries:$/) do |name, table|
  db_table = db.exec("select * from #{name}")
  table.hashes.each do |test_row|
    matching = db_table.select do |db_row|
      test_row.keys.all? do |key|
        db_row.has_key?(key) and (test_row[key] == db_row[key])
      end
    end
    if matching.empty?
      fail("The table '#{name}' should include the entry #{test_row.inspect}")
    end
  end
end
