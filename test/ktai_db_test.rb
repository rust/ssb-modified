require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'ssb/ktai_db.rb'
require 'nkf'

unit_tests do
  test 'default size should 30' do
    db = SSB::KtaiDB.new(true)
    assert_equal(db.size, 30)
  end

  test 'simple search' do
    db = SSB::KtaiDB.new(true)
    ret = db.search(:carrier => 'DoCoMo')
    assert_equal(ret.size, 10)

    ret = db.search(:carrier => 'au')
    assert_equal(ret.size, 10)
    ret = db.search(:carrier => 'KDDI')
    assert_equal(ret.size, 10)
    ret = db.search(:carrier => 'Tu-ka')
    assert_equal(ret.size, 10)

    ret = db.search(:carrier => 'SoftBank')
    assert_equal(ret.size, 10)
    ret = db.search(:carrier => 'Vodafone')
    assert_equal(ret.size, 10)
    ret = db.search(:carrier => 'ThirdForce')
    assert_equal(ret.size, 10)

    ret = db.search(:carrier => 'DoCoMo', :name => 'N') # N501i N502i NM502i
    assert_equal(ret.size, 3)
    assert_equal(ret[0][:name], 'N501i')
    assert_equal(ret[1][:name], 'N502i')
    assert_equal(ret[2][:name], 'NM502i')

    ret = db.search(:name => 'N') # N501i N502i NM502i
    assert_equal(ret.size, 3)
    assert_equal(ret[0][:name], 'N501i')
    assert_equal(ret[1][:name], 'N502i')
    assert_equal(ret[2][:name], 'NM502i')

    ret = db.search(:carrier => 'DoCoMo', :name => 'N5') # N501i N502i
    assert_equal(ret.size, 2)
    assert_equal(ret[0][:name], 'N501i')
    assert_equal(ret[1][:name], 'N502i')

    ret = db.search(:carrier => 'DoCoMo', :name => 'NM') # NM502i
    assert_equal(ret.size, 1)
    assert_equal(ret[0][:name], 'NM502i')
  end

  # useragentで検索するとき、完全一致のときは1件だけ
  test 'search by useragent fullmatch' do
    db = SSB::KtaiDB.new(true)
    ret = db.search(:useragent => 'UP.Browser/3.04-HI11 UP.Link/3.4.4')
    assert_equal(ret.size, 1)
    assert_equal(ret[0][:name], 'C302H')
  end
  
  # useragentで検索は前方からの部分一致でok
  test 'search by useragent partmatch' do
    db = SSB::KtaiDB.new(true)
    ret = db.search(:useragent => 'UP.Browser/3.04')
    assert_equal(ret.size, 8)
    assert_equal(ret[0][:name], 'C301T')
    assert_equal(ret[7][:name], 'C309H')
  end

  test 'test search nil' do
    db = SSB::KtaiDB.new(true)
    ktai = db.search(:carrier   => nil,
                     :name      => nil,
                     :useragent => nil)
    assert_not_nil(ktai)
    assert_instance_of(Array, ktai)
    assert_equal(ktai.size, 30)
  end
end

