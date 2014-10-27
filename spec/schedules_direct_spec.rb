require 'schedules_direct'

unless ENV['SD_TEST_USER'] and ENV['SD_TEST_HASH']
  puts <<EOF

NOTICE: You must set the following environment variables to run these
NOTICE: tests.
NOTICE:
NOTICE:   export SD_TEST_USER='username'
NOTICE:   export SD_TEST_HASH='SHA1 password hash'
NOTICE:
NOTICE: The password hash can be generated using the following command:
NOTICE:
NOTICE:   echo -n 'password' | shasum

EOF
  exit 1
end

describe "SchedulesDirect" do

  # Schedules Direct has request that we include the user's email in the user
  # agent string during testing.
  USER_AGENT = "schedules_direct/%s (%s)" %
    [ SchedulesDirect::VERSION, %x{git config user.email}.chomp ]

  # Our client
  subject(:sd) do
    SchedulesDirect.new username: ENV['SD_TEST_USER'],
                        password_hash: ENV['SD_TEST_HASH'],
                        user_agent: USER_AGENT
  end

  # The region we use for testing
  let(:region) { { country: 'USA', postalcode: 78701 } }

  # Grab a cable lineup for testing
  subject(:lineup) do
    (sd.all_lineups(region) - sd.lineups).first
  end
                                            
  describe 'initializer' do
    it 'will generate a password hash if password provided' do
      sd = SchedulesDirect.new
      sd.password = 'test123'
      expect(sd.password_hash).to \
        eql('7288edd0fc3ffcbe93a0cf06e3568e28521687bc')
    end
  end

  describe 'token' do
    it 'will return nil when request is false and no token active' do
      expect(sd.token(false)).to eql(nil)
    end
    it 'will request a new token when call with non-zero arg' do
      expect(sd.token).to_not eql(nil)
    end
    it 'will return the token when there is an active token' do
      first = sd.token
      expect(sd.token).to eql(first)
    end
    it 'will raise an error for invalid credentials' do
      sd.password = 'bad password'
      expect { sd.token }.to \
        raise_error(SchedulesDirect::InvalidCredentials)
    end
    it 'will raise an error for no username'
    it 'will raise an error for no password or password hash'
  end

  describe 'online?' do
    it 'will return true if system status is online' do
      status = sd.system_status
      status[0]['status'] = 'Online'
      expect(sd.online?).to eql(true)
    end
    it 'will return false if system status is online' do
      status = sd.system_status
      status[0]['status'] = 'something other than Online'
      expect(sd.online?).to eql(false)
    end
  end

  describe 'online!' do
    it 'will raise an exception when #online? returns false'
  end

  describe 'all_lineups' do
    it 'will return all lineups in the supplied region' do

      lineups = sd.headends(region).map do |key,headend|
        headend["lineups"].map do |data|
          data.merge! type: headend['type'], location: headend['location']
          SchedulesDirect::Lineup.new data
        end
      end.flatten

      expect(sd.all_lineups(region)).to match_array(lineups)
    end
  end

  describe 'add_lineup' do
    after { sd.delete_lineup(lineup) }
    it "will add a lineup to the user's lineups" do
      expect(sd.lineups).not_to include(lineup)
      sd.add_lineup lineup
      expect(sd.lineups).to include(lineup)
    end
  end

  describe 'delete_lineup' do
    before { sd.add_lineup(lineup) }
    it "will remove a lineup from the user's lineups" do
      expect(sd.lineups).to include(lineup)
      sd.delete_lineup lineup
      expect(sd.lineups).not_to include(lineup)
    end
  end
end
