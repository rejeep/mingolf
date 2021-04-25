module Mingolf
  class Runner
    COURSES = [
      %w[2ef1890b-1867-4ad5-9589-a12896888076 525b12ef-60a5-11d8-bc62-b74e72f35744], # Kungsbacka
      # %w[23aede8b-f55c-4706-8289-7b94d3212704 d98962ab-f4d5-4355-abe2-f3a1146ca9c3], # Vallda
      # %w[a9d7060f-0051-40fc-a021-98b885a55300 f6845066-ac12-4971-b7c9-327629d06b50], # St. Jörgen
    ].freeze

    def initialize(client, options, io: nil, courses: nil, attempts: nil, sleeper: nil, executor: nil)
      @client = client
      @date = options.fetch(:date)
      @from = options.fetch(:from)
      @to = options.fetch(:to)
      @slots = options.fetch(:slots)
      @sleep = options.fetch(:sleep, 60)
      @reject = options.fetch(:reject)
      @io = io || STDOUT
      @courses = courses || COURSES
      @attempts = attempts || 100_000
      @sleeper = sleeper || Kernel
      @executor = executor || Kernel
    end

    def run
      @client.login
      @attempts.times do
        free_slots = fetch_free_slots
        free_slots.reject! { |slot| eval(@reject) } if @reject
        if free_slots.empty?
          @io.puts('No free slots')
        else
          @io.puts("#{free_slots.size} free slots found")
          free_slots.each do |free_slot|
            slot_time_pretty = free_slot.fetch('SlotTime').strftime('%Y-%m-%d %H:%M')
            slot_organizational_unit_name = free_slot.fetch('OrganizationalunitName')
            @io.puts("#{slot_time_pretty} at #{slot_organizational_unit_name.inspect}")
          end
          @io.puts('')
          @executor.system("say '#{free_slots.size} free slots found'")
        end
        @sleeper.sleep(@sleep)
      end
    end

    def fetch_free_slots
      @courses.flat_map do |club_id, course_id|
        tee_times = @client.tee_times(club_id, course_id, @date)
        tee_times.fetch('Slots').select do |slot|
          slot_time = Time.strptime(slot.fetch('SlotTime'), '%Y%m%dT%H%M%S')
          if slot_time >= @from && slot_time <= @to
            participants = tee_times.fetch('Participants').dig(slot.fetch('SlotID'))
            if !participants || slot.fetch('MaximumNumberOfSlotBookingsPerSlot') - participants.size >= @slots
              slot.merge!('SlotTime' => slot_time)
            end
          end
        end
      end
    end
  end
end
