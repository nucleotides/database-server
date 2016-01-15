Then(/^the stderr excluding logging info should not contain anything$/) do
  stderr = all_commands.
    detect{|i| i.respond_to? :stderr}.
    stderr.lines.
    reject{|i| i =~ /^(.+clojure.tools.logging|INFO|WARNING).+$/}.
    join.strip
  expect(stderr).to eq("")
end

When(/^in bash I successfully run:$/) do |string|
    run_simple(unescape_text("bash -c '#{string}'"), fail_on_error = true)
end

When(/^in bash I run:$/) do |string|
    run_simple(unescape_text("bash -c '#{string}'"), fail_on_error = false)
end
