# coding: utf-8

require 'date'
require 'json'
require 'optparse'
require 'time'
require 'typhoeus'

class Mingolf
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36'.freeze

  COURSES = [
    %w[2ef1890b-1867-4ad5-9589-a12896888076 525b12ef-60a5-11d8-bc62-b74e72f35744], # Kungsbacka
    %w[23aede8b-f55c-4706-8289-7b94d3212704 d98962ab-f4d5-4355-abe2-f3a1146ca9c3], # Vallda
    %w[a9d7060f-0051-40fc-a021-98b885a55300 f6845066-ac12-4971-b7c9-327629d06b50], # St. Jörgen
  ].freeze

  def initialize(argv, http: nil, io: nil, courses: nil, attempts: nil, sleeper: nil, executer: nil)
    @options = parse_options(argv)
    @date = @options.fetch(:date)
    @from = @options.fetch(:from)
    @to = @options.fetch(:to)
    @slots = @options.fetch(:slots)
    @sleep = @options.fetch(:sleep, 60)
    @http = http || Typhoeus
    @io = io || STDOUT
    @courses = courses || COURSES
    @attempts = attempts || 100_000
    @sleeper = sleeper || Kernel
    @executer = executer || Kernel
  end

  def run
    login
    @attempts.times do
      free_slots = []
      @courses.each do |club_id, course_id|
        url = format(
          'https://mingolf.golf.se/handlers/booking/GetTeeTimesFullDay/%s/%s/%sT090000/1',
          course_id,
          club_id,
          @date.strftime('%Y%m%d'),
        )
        @io.puts(url)
        response = @http.get(
          url,
          cookiefile: cookiefile,
          cookiejar: cookiefile,
          headers: {
            'Accept' => '*/*',
            'User-Agent' => USER_AGENT,
          },
        )
        response_body = JSON.parse(response.body)
        response_body.fetch('Slots').each do |slot|
          slot_time = Time.strptime(slot.fetch('SlotTime'), '%Y%m%dT%H%M%S')
          if slot_time >= @from && slot_time <= @to
            participants = response_body.fetch('Participants').dig(slot.fetch('SlotID'))
            if !participants || slot.fetch('MaximumNumberOfSlotBookingsPerSlot') - participants.size >= @slots
              free_slots << slot
            end
          end
        end
      end
      if free_slots.empty?
        @io.puts('No free slots')
      else
        @io.puts("#{free_slots.size} free slots found")
        free_slots.each do |free_slot|
          slot_time = Time.strptime(free_slot.fetch('SlotTime'), '%Y%m%dT%H%M%S')
          slot_time_pretty = slot_time.strftime('%Y-%m-%d %H:%M')
          slot_organizational_unit_name = free_slot.fetch('OrganizationalunitName')
          @io.puts("#{slot_time_pretty} at #{slot_organizational_unit_name.inspect}")
        end
        @io.puts('')
        @executer.system %|say "#{free_slots.size} free slots found"|
      end
      @sleeper.sleep(@sleep)
    end
  end

  private

  def login
    @http.post(
      'https://mingolf.golf.se/handlers/login',
      body: {
        golfID: golf_id,
        password: password,
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

  def parse_options(argv)
    options = {}
    optparse = OptionParser.new do |opts|
      opts.on('--date DATE') do |date|
        options[:date] = Date.parse(date)
      end
      opts.on('--from FROM') do |from|
        options[:from] = Time.parse("#{options.fetch(:date)} #{from}")
      end
      opts.on('--to TO') do |to|
        options[:to] = Time.parse("#{options.fetch(:date)} #{to}")
      end
      opts.on('--slots SLOTS', Integer) do |slots|
        options[:slots] = slots
      end
      opts.on('--sleep SECONDS', Integer) do |seconds|
        options[:sleep] = seconds
      end
    end
    optparse.parse!(argv)
    options
  end

  def cookiefile
    File.join(__dir__, '..', '.cookie')
  end

  def golf_id
    auth[0]
  end

  def password
    auth[1]
  end

  def auth
    @auth ||= File.read(File.join(__dir__, '..', '.auth')).lines.map(&:strip)
  end
end
