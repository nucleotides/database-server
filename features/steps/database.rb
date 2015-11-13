require 'pg'
require 'awesome_print'
require 'diffy'

Given(/^an empty database without any tables$/) do
  db.exec("drop schema public cascade;")
  db.exec("create schema public;")
end

Then(/^the table "(.*?)" should have the entries:$/) do |name, table|
  entries = table_entries(name)
  table   = table.hashes.map do |row|
    row = Hash[row.map do |(k, v)|
      [k, entry_lookup(v.strip)]
    end]
  end

  table.each do |test_row|
    matching = entries.select do |db_row|
      test_row.keys.all? do |key|
        db_row.has_key?(key) and (test_row[key] == db_row[key].strip)
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
