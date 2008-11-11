require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'ssb/time_stamper'

unit_tests do
  test 'instance default' do
    stamp = SSB::TimeStamper.new
    assert stamp
    assert_instance_of(Hash, stamp.log)
    assert_equal(stamp.log.size, 0)
    assert_instance_of(Array, stamp.span_labels)
    assert_equal(stamp.span_labels.size, 0)
  end

  test 'instance with span definision' do
    stamp = SSB::TimeStamper.new({
                                   :test1 => [:test1_start, :test1_done],
                                   :test2 => [:test2_start, :test2_done],
                                   :test3 => [:test3_start, :test3_done],
                                   :total => [:test1_start, :test3_done],})
    assert stamp
    assert_instance_of(Hash, stamp.log)
    assert_equal(stamp.log.size, 0)
    assert_instance_of(Array, stamp.span_labels)
    assert_equal(stamp.span_labels.size, 4)
    assert(stamp.span_labels.include?(:test1))
    assert(stamp.span_labels.include?(:test2))
    assert(stamp.span_labels.include?(:test3))
    assert(stamp.span_labels.include?(:total))
  end

  test 'simple stamp collect' do
    stamp = SSB::TimeStamper.new
    now = Time.now

    stamped = stamp.stamp(:test)

    assert_equal(stamped.class, Time)
    assert(stamped >= now)
    assert((stamped - now).to_i < 1)
    assert_equal(stamp.count, 1)
    assert_equal(stamped, stamp[:test])
  end

  test 'stamp span' do
    stamp = SSB::TimeStamper.new({
                                   :test1 => [:test1_start, :test1_done],
                                   :test2 => [:test2_start, :test2_done],
                                   :test3 => [:test3_start, :test3_done],
                                   :total => [:test1_start, :test3_done],})

    stamp.stamp :test1_start, Time.at(1)
    stamp.stamp :test1_done, Time.at(2)
    assert_equal(stamp.count, 2)
    assert_equal(stamp.span(:test1), 1000)
    assert_equal(stamp.test1, 1000)

    stamp.stamp :test2_start, Time.at(3)
    stamp.stamp :test2_done, Time.at(5)
    assert_equal(stamp.count, 4)
    assert_equal(stamp.span(:test2), 2000)
    assert_equal(stamp.test2, 2000)

    stamp.stamp :test3_start, Time.at(8)
    stamp.stamp :test3_done, Time.at(13)
    assert_equal(stamp.count, 6)
    assert_equal(stamp.span(:test3), 5000)
    assert_equal(stamp.test3, 5000)

    assert_equal(stamp.span(:total), 12000)
    assert_equal(stamp.total, 12000)
  end
end
