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

    ret.each do |feature|
      logger.debug feature.title
      feature.product_contexts.each do |ctx|
        logger.debug "  #{ctx.product} #{ctx.status}"
      end
    end

  end

end
