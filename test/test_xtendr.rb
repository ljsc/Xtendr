require 'helper'
require 'fileutils'

class TestXtendr < Test::Unit::TestCase
  include FileUtils

  def setup
    @store = Xtendr(__FILE__)
  end

  def teardown
    Xtendr(__FILE__).remove_allx
  end

  def test_module
    test_file = __FILE__
    test_file.extend(Xtendr)
    test_file.setx('module', 'Foobar')
    assert_equal 'Foobar', test_file.getx('module')
  end

  def test_proxy
    @store.setx('proxy', 'Foobar')
    assert_equal 'Foobar', @store.getx('proxy')
  end

  def test_failing
    assert_nothing_raised do
      @store.getx('missing')
    end
  end

  def test_failing_bang
    assert_raises Errno::ENOATTR do
      @store.getx!('missing')
    end
  end

  def test_get_default
    assert_equal 'default', @store.getx('remove') { 'default' }
  end

  def test_listing
    @store.setx('listme', 'true')
    @store.setx('me_too', 'true')
    assert @store.listx.include?('listme')
    assert @store.listx.include?('me_too')
  end

  def test_removal
    @store.setx('hide', 'true')
    @store.setx('seek', 'true')
    @store.removex('hide')
    assert !@store.listx.include?('hide')
    assert @store.listx.include?('seek')
  end

  def test_remove_all
    @store.setx('hide', 'true')
    @store.setx('seek', 'true')
    @store.remove_allx
    assert !@store.listx.include?('hide')
    assert !@store.listx.include?('seek')
  end

  def test_create_option
    assert_nothing_raised do
      @store.setx('createme', 'done!', :create)
    end
    assert_raise Errno::EEXIST do
      @store.setx('createme', 'done!', :create)
    end
  end

  def test_replace_option
    assert_raise Errno::ENOATTR do
      @store.setx('replaceme', 'done!', :replace)
    end
    @store.setx('replaceme', 'done!')
    assert_nothing_raised do
      @store.setx('replaceme', 'done!', :replace)
    end
  end

  def test_link_nofollow
    link_file = File.expand_path('./test_link', File.dirname(__FILE__))
    ln_s __FILE__, link_file
    link_store = Xtendr(link_file)
    link_store.setx('dontfollow', 'justdont', :create, :no_follow)
    assert_nil @store.getx('dontfollow')
    assert_equal 'justdont', link_store.getx('dontfollow', :no_follow)
  ensure
    rm link_file
  end

  def test_link_follow
    link_file = File.expand_path('./test_link', File.dirname(__FILE__))
    ln_s __FILE__, link_file
    link_store = Xtendr(link_file)
    link_store.setx('dontfollow', 'justdont', :create)
    assert_equal 'justdont', @store.getx('dontfollow')
    assert_nil link_store.getx('dontfollow', :no_follow)
  ensure
    rm link_file
  end
end
