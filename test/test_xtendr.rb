require 'helper'

class TestXtendr < Test::Unit::TestCase
  def test_module
    test_file = __FILE__
    test_file.extend(Xtendr)
    test_file.setx('module', 'Foobar')
    assert_equal 'Foobar', test_file.getx('module')
  end

  def test_proxy
    store = Xtendr(__FILE__)
    store.setx('proxy', 'Foobar')
    assert_equal 'Foobar', store.getx('proxy')
  end

  def test_failing
    store = Xtendr(__FILE__)
    assert_nothing_raised do
      store.getx('missing')
    end
  end

  def test_failing_bang
    store = Xtendr(__FILE__)
    assert_raises Errno::ENOATTR do
      store.getx!('missing')
    end
  end

  def test_get_default
    store = Xtendr(__FILE__)
    store.removex('removed') if store.getx('remove')
    assert_equal 'default', store.getx('remove') { 'default' }
  end

  def test_listing
    store = Xtendr(__FILE__)
    store.setx('listme', 'true')
    store.setx('me_too', 'true')
    assert store.listx.include?('listme')
    assert store.listx.include?('me_too')
  end

  def test_removal
    store = Xtendr(__FILE__)
    store.setx('hide', 'true')
    store.setx('seek', 'true')
    store.removex('hide')
    assert !store.listx.include?('hide')
    assert store.listx.include?('seek')
  end

  def test_options
    store = Xtendr(__FILE__)
    store.removex('createme')
    assert_nothing_raised do
      store.setx('createme', 'done!', :create)
    end
    assert_raise Errno::EEXIST do
      store.setx('createme', 'done!', :create)
    end
  end

end
