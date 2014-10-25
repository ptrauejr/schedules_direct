require 'digest'
require 'rest_client'
require 'json'
require 'pry'
require "schedules_direct/version"
require "schedules_direct/lineup"

class SchedulesDirect
  BASE_URL = 'https://json.schedulesdirect.org/20140530'

  class InvalidCredentials < Exception; end
  class ServiceOffline < Exception; end

  attr_accessor :password_hash, :username
  attr_writer :token

  def initialize(p={})
    @username = p[:username]
    self.password=(p[:password]) if p[:password]
    @password_hash = p[:password_hash]
  end

  def password=(value)
    @password_hash = Digest::SHA1.hexdigest value
  end

  # Arguments:
  #   request: true means request a token if one is not active
  #            false means do not request a token if one is not active
  #            :force means always request a new token
  def token(request=true)
    return @token if request == false
    return @token if @token and request != :force

    begin
      json = RestClient.post "#{BASE_URL}/token",
        { username: @username, password: @password_hash }.to_json,
        content_type: 'application/json',
        user_agent: user_agent
    rescue RestClient::BadRequest => e
      # Raise a specific exception if the creds are wrong
      raise InvalidCredentials if
        JSON.parse(e.response)['response'] == "INVALID_USER"
      raise e
    end

    @token = JSON.parse(json)["token"]
  end

  def status(refresh=false)
    @status = nil if refresh
    @status ||= get "status"
  end

  def system_status(refresh=false)
    status(refresh)['systemStatus']
  end

  def online?(refresh=false)
    # For some absurd system status is an array..
    system_status(refresh)[0]['status'] == 'Online'
  end

  def online!
    online? or raise ServiceOffline
  end

  def headends(p={})
    online!
    raise 'No :country' unless p[:country]
    raise 'No :postalcode' unless p[:postalcode]
   
    get "headends", country: p[:country], postalcode: p[:postalcode]
  end

  def all_lineups(p={})
    online!
    headends(p).each_value.map do |headend|
      headend["lineups"].map do |data|
        Lineup.new data.merge(type: headend["type"],
                              location: headend["location"])
      end
    end.flatten
  end

  def lineups
    online!
    get("lineups")["lineups"].map do |data|
      Lineup.new data
    end
  end

  def add_lineup(lineup)
    # XXX uri overlaps the base_url for some reason 
    put(lineup.uri)
  end

  private

  def get(path, p={})
    buf = RestClient.get "#{BASE_URL}/#{path}", params: p, token: token
    JSON.parse(buf)
  end

  def put(path, p={})
    buf = RestClient.put "#{BASE_URL}/#{path}", token: token
    result = JSON.parse(buf)
    result["response"] == "OK"
  end

  def user_agent
    "schedules_direct/#{SchedulesDirect::VERSION} " +
      "rest-client/#{RestClient.version}"
  end
end
