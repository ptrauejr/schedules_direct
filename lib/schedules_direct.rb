require 'digest'
require 'rest_client'
require 'json'
require 'pry'
require "schedules_direct/version"
require "schedules_direct/lineup"

class SchedulesDirect
  BASE_URL = 'https://json.schedulesdirect.org/'
  API_VERSION = '20140530'

  class InvalidCredentials < Exception; end
  class ServiceOffline < Exception; end

  attr_accessor :password_hash, :username, :user_agent
  attr_writer :token

  def initialize(p={})
    @username = p[:username]
    self.password=(p[:password]) if p[:password]
    @password_hash = p[:password_hash]
    @user_agent = p[:user_agent] || "schedules_direct/#{VERSION}"
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
      json = RestClient.post "#{BASE_URL}/#{API_VERSION}/token",
        { username: @username, password: @password_hash }.to_json,
        content_type: 'application/json',
        user_agent: @user_agent
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
    @status ||= get(api_path("status"))
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
   
    get api_path("headends"), country: p[:country], postalcode: p[:postalcode]
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
    begin
      get(api_path("lineups"))["lineups"].map { |data| Lineup.new data }
    rescue RestClient::BadRequest => e
      # We get an error when there are no lineups, instead of an empty list
      response = JSON.parse(e.response)
      raise e unless response['response'] == 'NO_LINEUPS'
      []
    end
  end

  def add_lineup(lineup)
    put(lineup.uri)
  end

  def delete_lineup(lineup)
    delete(lineup.uri)
  end

  private

  def api_path(path)
    "#{API_VERSION}/#{path}"
  end

  def get(path, params={})
    buf = RestClient.get "#{BASE_URL}/#{path}", params: params,
            user_agent: @user_agent, token: token
    JSON.parse(buf)
  end

  def put(path, params={})
    buf = RestClient.put "#{BASE_URL}/#{path}", params,
            user_agent: @user_agent, token: token
    result = JSON.parse(buf)
    result["response"] == "OK"
  end

  def delete(path)
    buf = RestClient.delete "#{BASE_URL}/#{path}",
            user_agent: @user_agent, token: token
    result = JSON.parse(buf)
    result['response'] == "OK"
  end
end
