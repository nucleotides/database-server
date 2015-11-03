require 'pg'
require 'awesome_print'
require 'diffy'

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

def table_entries(name)
  result = db.exec("select * from #{name}")
  result.map{|i| Hash[i]}
end

Given(/^an empty database without any tables$/) do
  db.exec("drop schema public cascade;")
  db.exec("create schema public;")
end

Then(/^the table "(.*?)" should have the entries:$/) do |name, table|
  entries = table_entries(name)
  table.hashes.each do |test_row|
    matching = entries.select do |db_row|
      test_row.keys.all? do |key|
        db_row.has_key?(key) and (test_row[key].strip == db_row[key].strip)
      end
    end
    if matching.empty?
      row   = test_row.awesome_inspect
      table = entries.map(&:awesome_inspect).join("\n")
      diff  = Diffy::Diff.new(row, table)
      fail("The table '#{name}' should include the entry:\n#{row}\n\nDiff:\n\n#{diff}")
    end
  end
end
