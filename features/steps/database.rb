require 'pg'
require 'awesome_print'
require 'diffy'


Given(/^an empty database without any tables$/) do
  drop_all_tables
end

Given(/^a clean database$/) do
  drop_all_tables
  create_tables
end

Given(/^the database scenario with "(.*?)"$/) do |scenario_name|
  drop_all_tables
  create_tables
  execute_sql_fixture(scenario_name.strip.gsub(" ", "_"))
end

Given(/^the database fixtures:$/) do |table|
  table.hashes.each do |row|
    execute_sql_fixture(row['fixture'])
  end
end

Then(/^the following tables should not be empty:$/) do |table|
  table.hashes.each do |row|
    expect(table_entries(row['name']).length).to_not be(0)
  end
end

Then(/^the table "(.*?)" should include the entries:$/) do |name, table|
  entries = table_entries(name)
  table   = table.hashes.map do |row|
    row = Hash[row.map do |(k, v)|
      [k, entry_lookup(v.to_s.strip)]
    end]
  end

  table.each do |test_row|
    matching = entries.select do |db_row|
      test_row.keys.all? do |key|
        db_row.has_key?(key) and (test_row[key].to_s.strip == db_row[key].to_s.strip)
      end
    end
    if matching.empty?
      row   = test_row.sorted_awesome_inspect
      table = entries.map(&:sorted_awesome_inspect).join("\n")
      diff  = Diffy::Diff.new(row, table)
      fail("The table '#{name}' should include the entry:\n#{row}\n\nDiff:\n\n#{diff}")
    end
  end
end


Then(/^the table "(.*?)" should not include the entries:$/) do |name, table|
  entries = table_entries(name)
  table   = table.hashes.map do |row|
    row = Hash[row.map do |(k, v)|
      [k, entry_lookup(v.to_s.strip)]
    end]
  end

  table.each do |test_row|
    matching = entries.select do |db_row|
      test_row.keys.all? do |key|
        db_row.has_key?(key) and (test_row[key].to_s.strip == db_row[key].to_s.strip)
      end
    end
    if not matching.empty?
      row   = test_row.sorted_awesome_inspect
      fail("The table '#{name}' should not include the entry:\n#{row}")
    end
  end
end

Then(/^the table "(.*?)" should contain "(.*?)" rows$/) do |table, count|
  expect(table_entries(table).count).to eq(count.to_i)
end
