require 'date'
require 'time'
require 'optparse'

module Mingolf
  class Cli
    def self.parse(argv)
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
  end
end
