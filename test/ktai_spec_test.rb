require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'ssb/ktai_spec.rb'

unit_tests do
  TEST_UA    = 'DoCoMo/2.0 N902i(c100;TB;hid;icc)'
  TEST_PROPS = {
    :useragent => 'DoCoMo/2.0 N902i',
    :uid       => 'uid',
    :hid       => 'hid',
    :icc       => 'icc',
    :extra     => '拡張データ',
  }
  MUST_KEYS = [
    :useragent,
    :uid,
    :hid,
    :icc,
    :exheader,
  ]

  def setup
    @spec = Array.new
    @spec[0] = SSB::KtaiSpec.new(TEST_UA);
    @spec[1] = SSB::KtaiSpec.new(TEST_PROPS);
  end

  # デフォルトプロパティはキーとして存在する必要あり
  test 'default_props' do
    @spec.each do |spec|
      MUST_KEYS.each do |key|
        assert(spec.has_key?(key))
        assert_equal(spec[key].class, String)
      end
    end
  end

  # 拡張プロパティがちゃんと格納されるか
  test 'extra_prop' do
    assert(@spec[1].has_key?(:extra))
    assert_equal(@spec[1][:extra], '拡張データ')
  end

  # ユーザエージェント文字列が正しいか
  test 'useragent' do
    assert(@spec[0][:useragent])
    assert_equal(@spec[0][:useragent], TEST_UA)
    assert_equal(@spec[0].get_useragent, TEST_UA)

    assert(@spec[1][:useragent])
  end
end
