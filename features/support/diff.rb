def diff(a, b)
  Diffy::Diff.new(a.sorted_awesome_inspect, b.sorted_awesome_inspect)
end
