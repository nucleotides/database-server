class Array

  def sorted_awesome_inspect
    self.sort_by(&:first).map(&:sorted_awesome_inspect).join("\n")
  end

end
