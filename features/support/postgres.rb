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

def entry_lookup(entry)
  return entry unless entry.start_with?('$')
  table, query_string = entry[1..-1].split("?")
  query_params = query_string.split("&").map{|i| i.split('=').join(" = ")}.join(" and ")
  query = "select id from #{table} where #{query_params}"
  result = db.exec(query).values
  if result.length > 1
    raise "The query \"#{query}\" returned multiple IDs"
  elsif result.length < 1
    raise "The query \"#{query}\" returned no IDs"
  end
  result.first.first
end

def execute_sql_file(path)
  fail("Fixture does not exist - #{path}") unless File.exists? path
  db.exec(File.read(path))
end

def drop_all_tables
  db.exec("drop schema public cascade;")
  db.exec("create schema public;")
end

def create_tables
  execute_sql_file('resources/migrations/2015101019150000-create-tables.up.sql')
end

def execute_sql_fixture(fixture_name)
  execute_sql_file("test/fixtures/#{fixture_name}.sql")
end
