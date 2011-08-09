require File.join(File.dirname(__FILE__), 'helper')

class Query_test < Test::Unit::TestCase

  def test_active_record_style

    Feta::Logging.logger = Logger.new(STDERR)
    Feta::Logging.logger.level = Logger::DEBUG

    # No client set yet
    assert_raise RuntimeError do
      Feta::Feature.query.only_actor("dmacvicar@novell.com").with_role("teamlead").each do |feature|
        puts feature
      end
    end

    Feta.client = Feta::Client.new("https://fate.novell.com")
    ret  = Feta::Feature.query.only_actor("dmacvicar@novell.com").to_a
    #assert ret.collect(&:id).include?(645150)

    STDERR.puts ret.collect(&:id)

    ret.each do |feature|
      STDERR.puts feature.title
      feature.product_contexts.each do |ctx|
        STDERR.puts "  #{ctx.product} #{ctx.status}"
      end
    end

  end

end
