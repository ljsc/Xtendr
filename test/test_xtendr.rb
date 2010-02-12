require 'helper'

class TestXtendr < Test::Unit::TestCase
  def test_module
    test_file = __FILE__
    test_file.extend(Xtendr)
    test_file.set_xattr('module', 'Foobar')
    assert_equal 'Foobar', test_file.get_xattr('module')
  end

  def test_proxy
    store = Xtendr(__FILE__)
    store.set_xattr('proxy', 'Foobar')
    assert_equal 'Foobar', store.get_xattr('proxy')
  end

  def test_failing
    store = Xtendr(__FILE__)
    assert_nothing_raised do
      store.get_xattr('missing')
    end
  end

  def test_failing_bang
    store = Xtendr(__FILE__)
    assert_raises Errno::ENOATTR do
      store.get_xattr!('missing')
    end
  end

  def test_listing
    store = Xtendr(__FILE__)
    store.set_xattr('listme', 'true')
    store.set_xattr('me_too', 'true')
    assert store.list_xattrs.include?('listme')
    assert store.list_xattrs.include?('me_too')
  end

  def test_removal
    store = Xtendr(__FILE__)
    store.set_xattr('hide', 'true')
    store.set_xattr('seek', 'true')
    store.remove_xattr('hide')
    assert !store.list_xattrs.include?('hide')
    assert store.list_xattrs.include?('seek')
  end

end
