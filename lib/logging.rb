require 'semantic_logger'

# TODO, if this is run as a library in an application, these should be configurable.
SemanticLogger.default_level = :trace
SemanticLogger.add_appender(io: $stdout, formatter: :color)

