$: << File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'feta'

if ENV["DEBUG"]
  Feta::Logging.logger = Logger.new(STDERR)
  Feta::Logging.logger.level = Logger::DEBUG
end
