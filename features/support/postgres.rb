PARAMS = {
  user:      "PGUSER",
  password:  "PGPASSWORD",
  host:      "PGHOST",
  port:      "PGPORT",
  dbname:    "PGDATABASE"
}

def db
  return @conn if @conn

  params = Hash[PARAMS.map do |k,v|
    [k, ENV[v]]
  end]

  @conn ||= PG.connect(params)
  @conn.exec("set client_min_messages = warning")
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
  query = "select * from #{table} where #{query_params}"
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
  Dir["resources/migrations/*.up.sql"].each do |f|
    execute_sql_file(f)
  end
end

def execute_sql_fixture(fixture_name)
  execute_sql_file("test/fixtures/#{fixture_name}.sql")
end
