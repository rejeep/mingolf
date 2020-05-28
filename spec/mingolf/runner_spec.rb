require 'mingolf/client'
require 'mingolf/runner'

describe Mingolf::Runner do
  let :client do
    instance_double(Mingolf::Client)
  end

  let :date do
    Date.new(2020, 5, 30)
  end

  let :options do
    {
      date: date,
      from: Time.new(2020, 5, 30, 10, 0),
      to: Time.new(2020, 5, 30, 15, 0),
      slots: 2,
    }
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
    double(:sleeper)
  end

  let :executor do
    double(:executor, system: nil)
  end

  let :slot_time do
    '20200530T113000'
  end

  let :maximum_number_of_slot_bookings_per_slot do
    4
  end

  let :tee_times_participants do
    {
      'SLOT_ID' => [
        {'ExactHcp' => '1,2'},
        {'ExactHcp' => '3,4'},
      ],
    }
  end

  let :tee_times do
    {
      'Slots' => [
        {
          'MaximumNumberOfSlotBookingsPerSlot' => maximum_number_of_slot_bookings_per_slot,
          'SlotID' => 'SLOT_ID',
          'SlotTime' => slot_time,
          'OrganizationalunitName' => 'OrganizationalunitName',
        },
      ],
      'Participants' => tee_times_participants,
    }
  end

  subject :runner do
    described_class.new(
      client,
      options,
      io: io,
      courses: courses,
      attempts: 1,
      sleeper: sleeper,
      executor: executor,
    )
  end

  before do
    allow(sleeper).to receive(:sleep).with(60)
    allow(client).to receive(:login)
    allow(client).to receive(:tee_times).with('CLUB_ID', 'COURSE_ID', date).and_return(tee_times)
  end

  shared_examples 'free slot found' do
    it 'prints information about free slot' do
      runner.run
      expect(io).to have_received(:puts).with('1 free slots found')
      expect(io).to have_received(:puts).with('2020-05-30 11:30 at "OrganizationalunitName"')
    end

    it 'says information about free slot' do
      runner.run
      expect(executor).to have_received(:system).with('say "1 free slots found"')
    end
  end

  shared_examples 'no free slot found' do
    it 'prints no free slots' do
      runner.run
      expect(io).to have_received(:puts).with('No free slots')
    end

    it 'does not say anything' do
      runner.run
      expect(executor).not_to have_received(:system)
    end
  end

  include_examples 'free slot found'

  it 'logs in' do
    runner.run
    expect(client).to have_received(:login)
  end

  context 'when slot time is outside range' do
    let :slot_time do
      '20200530T080000'
    end

    include_examples 'no free slot found'
  end

  context 'when number of free slots is not enough' do
    let :tee_times do
      super().tap do |body|
        body['Participants']['SLOT_ID'] << {'ExactHcp' => '5,6'}
        body['Participants']['SLOT_ID'] << {'ExactHcp' => '7,8'}
      end
    end

    include_examples 'no free slot found'
  end

  context 'when slot id is not part of participants' do
    let :tee_times_participants do
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
