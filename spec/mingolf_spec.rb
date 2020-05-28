# coding: utf-8
require 'mingolf'

describe Mingolf do
  let :argv do
    %w[--date 2020-05-30 --from 10:00 --to 15:00 --slots 2]
  end

  let :http do
    double(:http)
  end

  let :io do
    double(:io, puts: nil)
  end

  let :courses do
    [
      %w[CLUB_ID COURSE_ID],
    ]
  end

  let :sleeper do
    double(:sleeper, sleep: nil)
  end

  let :executer do
    double(:executer, system: nil)
  end

  let :slot_time do
    '20200530T113000'
  end

  let :maximum_number_of_slot_bookings_per_slot do
    4
  end

  let :tee_times_full_day_response_body_participants do
    {
      'SLOT_ID' => [
        {'ExactHcp' => '1,2'},
        {'ExactHcp' => '3,4'},
      ],
    }
  end

  let :tee_times_full_day_response_body do
    {
      'Slots' => [
        {
          'MaximumNumberOfSlotBookingsPerSlot' => maximum_number_of_slot_bookings_per_slot,
          'SlotID' => 'SLOT_ID',
          'SlotTime' => slot_time,
          'OrganizationalunitName' => 'OrganizationalunitName',
        },
      ],
      'Participants' => tee_times_full_day_response_body_participants,
    }
  end

  let :tee_times_full_day_response do
    double(:tee_times_full_day_response, body: JSON.dump(tee_times_full_day_response_body))
  end

  let :tee_times_full_day_url do
    'https://mingolf.golf.se/handlers/booking/GetTeeTimesFullDay/COURSE_ID/CLUB_ID/20200530T090000/1'
  end

  subject :mingolf do
    described_class.new(
      argv,
      http: http,
      io: io,
      courses: courses,
      attempts: 1,
      sleeper: sleeper,
      executer: executer,
    )
  end

  before do
    allow(http).to receive(:post).with('https://mingolf.golf.se/handlers/login', anything)
    allow(http).to receive(:get).with(tee_times_full_day_url, anything).and_return(tee_times_full_day_response)
  end

  shared_examples 'free slot found' do
    it 'prints information about free slot' do
      mingolf.run
      expect(io).to have_received(:puts).with('Free slots found')
      expect(io).to have_received(:puts).with('2020-05-30 11:30:00 +0200 at OrganizationalunitName')
    end

    it 'says information about free slot' do
      mingolf.run
      expect(executer).to have_received(:system).with('say "1 free slots found"')
    end
  end

  shared_examples 'no free slot found' do
    it 'prints no free slots' do
      mingolf.run
      expect(io).to have_received(:puts).with('No free slots')
    end

    it 'does not say anything' do
      mingolf.run
      expect(executer).not_to have_received(:system)
    end
  end

  include_examples 'free slot found'

  context 'when slot time is outside range' do
    let :slot_time do
      '20200530T080000'
    end

    include_examples 'no free slot found'
  end

  context 'when number of free slots is not enough' do
    let :tee_times_full_day_response_body do
      super().tap do |body|
        body['Participants']['SLOT_ID'] << {'ExactHcp' => '5,6'}
        body['Participants']['SLOT_ID'] << {'ExactHcp' => '7,8'}
      end
    end

    include_examples 'no free slot found'
  end

  context 'when slot id is not part of participants' do
    let :tee_times_full_day_response_body_participants do
      {}
    end

    include_examples 'free slot found'
  end

  context 'when maximum number of slot bookings per slot is zero' do
    let :maximum_number_of_slot_bookings_per_slot do
      0
    end

    include_examples 'no free slot found'
  end
end
