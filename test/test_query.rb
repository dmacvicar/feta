require File.join(File.dirname(__FILE__), 'helper')

class Query_test < Test::Unit::TestCase

  include ::Feta::Logging

  def test_active_record_style

    # No client set yet
    assert_raise RuntimeError do
      Feta::Feature.query.only_actor("dmacvicar@novell.com").with_role("teamlead").each do |feature|
        puts feature
      end
    end

    Feta.client = Feta::Client.new("https://fate.novell.com")
    query  = Feta::Feature.query.only_actor("dmacvicar@novell.com").only_product("openSUSE-11.4")

    ret = query.each.to_a

    assert ret.collect(&:id).include?("303793")

    feature = ret.collect.select {|x| x.id == "303793"}.first

    assert_equal :rejected, feature.status_for_product("openSUSE-11.2")
    assert_equal :important, feature.priority_for_product_and_role("openSUSE-11.2", :productmanager)
    assert_nil feature.priority_for_product_and_role("openSUSE-11.2", :nobody)

    assert_equal :done, feature.status_for_product("openSUSE-11.4")
  end

end
