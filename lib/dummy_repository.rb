class DummyRepository
  def initialize consultants
    @consultants = consultants
  end

  def get_all_consultants
    @consultants
  end

  def update_consultant consultant
    @consultants[consultant.beeline_guid] = consultant
  end
end