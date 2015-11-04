Then(/^the stderr excluding logging info should not contain anything$/) do
  stderr = all_commands.
    detect{|i| i.respond_to? :stderr}.
    stderr.lines.
    reject{|i| i =~ /^(.+clojure.tools.logging|INFO).+$/}.
    join.strip
  expect(stderr).to eq("")
end
