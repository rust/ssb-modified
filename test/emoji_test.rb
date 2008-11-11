require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'ssb/emoji.rb'
require 'ssb/ktai_spec.rb'

unit_tests do
  def conv(carrier, str, is_utf8=false)
    term = flexmock(:get_carrier => carrier)
    SSB::Emoji.emoji_conv(term, str, is_utf8)
  end
  
  # docomo
  test 'docomo cref dec' do
    assert_equal(conv(SSB::KtaiSpec::CARRIER_DOCOMO, '&#63867;'), "<img class=\"emoji\" src=\"emoji/docomo/F97B.gif\" />")
  end

  test 'docomo direct binary' do
    assert_equal(conv(SSB::KtaiSpec::CARRIER_DOCOMO, "\xF9\x7B"), "<img class=\"emoji\" src=\"emoji/docomo/F97B.gif\" />")
  end

  test 'docomo cref hex extension' do
    assert_equal(conv(SSB::KtaiSpec::CARRIER_DOCOMO, "&#xE70C;"), "<img class=\"emoji\" src=\"emoji/docomo/F9B1.gif\" />")
  end

  test 'docomo utf8 binary' do
    assert_equal(conv(SSB::KtaiSpec::CARRIER_DOCOMO, "\xEE\x98\xBE", true), "<img class=\"emoji\" src=\"emoji/docomo/F89F.gif\" />")
  end
  
  # ezweb
  test 'ezweb localsrc' do
    assert_equal(conv(SSB::KtaiSpec::CARRIER_KDDI, '<img localsrc="54" />'), "<img class=\"emoji\" src=\"emoji/kddi/054.gif\" />")
  end

  test 'ezweb cref hex' do
    assert_equal(conv(SSB::KtaiSpec::CARRIER_KDDI, '&#xE481;'), "<img class=\"emoji\" src=\"emoji/kddi/001.gif\" />")
  end
  
  # thirdforce
  test 'vodafone sjis escape sequence' do
    assert_equal(conv(SSB::KtaiSpec::CARRIER_SOFTBANK, "\x1B\$Q>\x0F"), "<img class='emoji' src='emoji/softbank/E51E.gif' />")
    assert_equal(conv(SSB::KtaiSpec::CARRIER_SOFTBANK, "\x1B\$G!\x0F"), "<img class='emoji' src='emoji/softbank/E001.gif' />")
  end

  test 'vodafone unicode cref hex' do
    assert_equal(conv(SSB::KtaiSpec::CARRIER_SOFTBANK, '&#xE001;'), "<img class='emoji' src='emoji/softbank/E001.gif' />")
    assert_equal(conv(SSB::KtaiSpec::CARRIER_SOFTBANK, '&#xE427;'), "<img class='emoji' src='emoji/softbank/E427.gif' />")
  end
end

