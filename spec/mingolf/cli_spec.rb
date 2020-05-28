require 'mingolf/cli'

describe Mingolf::Cli do
  let :argv do
    %w[--date 2020-05-30 --from 10:00 --to 15:00 --slots 2 --sleep 42]
  end

  let :options do
    described_class.parse(argv)
  end

  let :expected_options do
    {
      date: Date.new(2020, 5, 30),
      from: Time.new(2020, 5, 30, 10, 0, 0, '+02:00'),
      to: Time.new(2020, 5, 30, 15, 0, 0, '+02:00'),
      slots: 2,
      sleep: 42,
    }
  end

  it 'parses cli argv and returns options' do
    expect(options).to eq(expected_options)
  end
end
