# time_stamper.rb - process time stamp
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: time_stamper.rb 2707 2007-12-06 23:57:12Z coji $
#
module SSB
  class TimeStamper
    attr_reader :log

    # { span_label => [stamp_from, stamp_to], ... }
    def initialize(span_defs = nil)
      @span_defs = Hash.new
      @span_defs.update(span_defs) unless span_defs.nil?
      @log = Hash.new
    end

    def span_labels
      @span_defs.keys
    end

    def span(label)
      diff(@span_defs[label][0], @span_defs[label][1])
    end

    def stamp(stamp, time = Time.now)
      @log[stamp] = time
    end

    def diff(stamp_from, stamp_to)
      ((@log[stamp_to].to_f - @log[stamp_from].to_f)*1000).to_i
    end

    def count
      @log.size
    end

    def[](label)
      @log[label]
    end

    def method_missing(msg, *args)
      if span_labels.include?(msg.to_sym)
        span(msg.to_sym)
      else
        super
      end
    end
  end
end
