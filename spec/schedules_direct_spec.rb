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
  describe 'initializer' do
    it 'will generate a password hash if password provided' do
      sd = SchedulesDirect.new
      sd.password = 'test123'
      expect(sd.password_hash).to \
        eql('7288edd0fc3ffcbe93a0cf06e3568e28521687bc')
    end
  end

  describe 'token' do
    let (:sd) do
      SchedulesDirect.new username: ENV['SD_TEST_USER'],
                          password_hash: ENV['SD_TEST_HASH']
    end
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
    let (:sd) do
      SchedulesDirect.new username: ENV['SD_TEST_USER'],
                          password_hash: ENV['SD_TEST_HASH']
    end
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
    
end
