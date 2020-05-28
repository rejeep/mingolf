require 'date'
require 'json'
require 'typhoeus'

module Mingolf
  class Client
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36'.freeze

    def initialize(http: nil, file: nil)
      @http = http || Typhoeus
      @file = file || File
    end

    def login
      @http.post(
        'https://mingolf.golf.se/handlers/login',
        body: {
          golfID: auth[0],
          password: auth[1],
          remember: false,
        },
        cookiefile: cookiefile,
        cookiejar: cookiefile,
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
          'User-Agent' => USER_AGENT,
        },
      )
    end

    def tee_times(club_id, course_id, date)
      url = format(
        'https://mingolf.golf.se/handlers/booking/GetTeeTimesFullDay/%<course_id>s/%<club_id>s/%<date>sT090000/1',
        course_id: course_id,
        club_id: club_id,
        date: date.strftime('%Y%m%d'),
      )
      response = @http.get(
        url,
        cookiefile: cookiefile,
        cookiejar: cookiefile,
        headers: {
          'Accept' => '*/*',
          'User-Agent' => USER_AGENT,
        },
      )
      JSON.parse(response.body)
    end

    private

    def cookiefile
      @file.join(Mingolf::ROOT_PATH, '.cookie')
    end

    def auth
      @auth ||= @file.read(File.join(Mingolf::ROOT_PATH, '.auth')).lines.map(&:strip)
    end
  end
end
