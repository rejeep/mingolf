require 'mingolf/client'

describe Mingolf::Client do
  let :http do
    double(:http)
  end

  let :file do
    class_double(File)
  end

  let :auth do
    <<~AUTH
      GOLF_ID
      PASSWORD
    AUTH
  end

  subject :client do
    described_class.new(http: http, file: file)
  end

  before do
    allow(file).to receive(:join).with(anything, '.cookie').and_return('cookiefile')
    allow(file).to receive(:read).with(/.auth/).and_return(auth)
  end

  describe '#login' do
    before do
      allow(http).to receive(:post)
    end

    it 'logs in' do
      client.login
      expect(http).to have_received(:post).with(
        'https://mingolf.golf.se/handlers/login',
        body: {
          golfID: 'GOLF_ID',
          password: 'PASSWORD',
          remember: false,
        },
        cookiefile: 'cookiefile',
        cookiejar: 'cookiefile',
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
          'User-Agent' => described_class::USER_AGENT,
        },
      )
    end
  end

  describe '#tee_times' do
    let :club_id do
      'CLUB_ID'
    end

    let :course_id do
      'COURSE_ID'
    end

    let :date do
      Date.new(2020, 5, 30)
    end

    let :expected_tee_times do
      {'Tee' => 'Times'}
    end

    before do
      allow(http).to receive(:get).with(
        'https://mingolf.golf.se/handlers/booking/GetTeeTimesFullDay/COURSE_ID/CLUB_ID/20200530T090000/1',
        cookiefile: 'cookiefile',
        cookiejar: 'cookiefile',
        headers: {
          'Accept' => '*/*',
          'User-Agent' => described_class::USER_AGENT,
        },
      ).and_return(double(:response, body: '{"Tee": "Times"}'))
    end

    it 'returns list of tee times' do
      tee_times = client.tee_times(club_id, course_id, date)
      expect(tee_times).to eq(expected_tee_times)
    end
  end
end
