require 'celluloid/autostart'
require 'cheflow/version'
require 'ridley'
require 'ridley-connectors'
require 'berkshelf'

Celluloid.logger.level = ::Logger::ERROR

module Cheflow
  require 'cheflow/cookbook'
end
