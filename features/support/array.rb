class Array

  def sorted_awesome_inspect
    self.sort.map(&:sorted_awesome_inspect).join("\n")
  end

end
