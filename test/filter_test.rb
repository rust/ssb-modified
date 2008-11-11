require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'ssb/emoji.rb'
require 'ssb/ktai_spec.rb'
require 'ssb.rb'

unit_tests do
  test 'filter a tag' do
    term = flexmock("term")
    term.should_receive(:get_carrier).and_return(SSB::KtaiSpec::CARRIER_DOCOMO)
    expected = %Q{<a href=\"./?ssb_q=http%3A%2F%2Fexample.com%3A80%2Fbar\" target=\"_top\">foo</a>}
    filtered = SSB::Application.filter_html("<a href='/bar'>foo</a>", URI.parse('http://example.com/foo'), term, '')
    assert_equal(expected, filtered)
  end
end
