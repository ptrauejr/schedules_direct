
class SchedulesDirect;end
class SchedulesDirect::Lineup
  attr_reader :name, :uri, :type, :location

  def initialize(p={})
    p = p.inject({}) { |o,(k,v)| o[k.to_sym] = v; o }
    @name = p[:name] or raise 'No :name'
    @uri = p[:uri] or raise 'No :uri'
    @type = p[:type]
    @location = p[:location]
  end

  def ==(other)
    other.class == self.class and
      other.name == @name and
      other.uri == @uri and
      other.type == @type and
      other.location == @location
  end
end
