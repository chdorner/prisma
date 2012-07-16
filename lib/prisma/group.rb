module Prisma
  # Represents a configured group, has convenience methods for getting data.
  class Group
    # The name of the group, typically a +Symbol+
    attr_accessor :name

    # The type of the group, +:counter+ or +:bitmap+
    attr_accessor :type

    # The description of the group, typcially a +String+
    attr_accessor :description

    # Block which gets called to evaluate if request should be counted and depending on the type how the request should be counted.
    # When +type+ is +:counter+ the request is getting counted as long as the return value is not nil or false.
    # When +type+ is +:bitmap+ the request is getting counted as long as the return value is an integer.
    attr_accessor :block

    # Initialize +Group+ from a hash
    def initialize(options = {})
      options.reverse_merge!(type: :counter)
      raise ArgumentError.new("Type #{options[:type].inspect} not allowed") unless [:counter, :bitmap].include?(options[:type])

      self.name = options[:name]
      self.type = options[:type]
      self.description = options[:description]
      self.block = options[:block]
    end

    # Get a +Hash+ with the +Date+ as key and amount of items as the value. Grouped by day.
    #     group.range(5.days.ago.to_date..Date.today)
    #     group.daily(5.days.ago.to_date..Date.today)
    # @param [Range] range of days
    # @return [Hash]
    def range(range)
      range = range..range if range.is_a? Date
      data = {}
      range.each do |date|
        case type
        when :counter
          data[date] = Prisma.redis.get(Prisma.redis_key(name, date)).to_i
        when :bitmap
          bitstring = Prisma.redis.get(Prisma.redis_key(name, date)) || ''
          string = bitstring.unpack('b*').first
          data[date] = string.count('1')
        end
      end
      data
    end
    alias_method :daily, :range

    # Get a +Hash+ with the +Date+ as key and amount of items as the value. Grouped by week, key represents a +Date+ object of the first day of the week.
    #     group.weekly(1.week.ago.to_date..Date.today)
    # @param [Range] range of days
    # @return [Hash]
    def weekly(range)
      data = range(range)
      data = data.group_by { |date, value| date.beginning_of_week }

      sum_up_grouped_data(data)
    end

    # Get a +Hash+ with the +Date+ as key and amount of items as the value. Grouped by month, key represents a +Date+ object of the first day of the month.
    #     group.monthly(1.month.ago.to_date..Date.today)
    # @param [Range] range of days
    # @return [Hash]
    def monthly(range)
      data = range(range)
      data = data.group_by { |date, value| date.beginning_of_month }

      sum_up_grouped_data(data)
    end

    private

    def sum_up_grouped_data(data)
      data.each do |date, values|
        data[date] = values.inject(0) { |sum, value| sum + value.second }
      end
    end
  end
end

