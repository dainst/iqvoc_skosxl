namespace :iqvoc do
  namespace :import do

    desc 'Imports iDAI.field value lists from a given SKOS ntriples file (FILE=...) and a default namespace URL (NAMESPACE_URL=...)'
    task :idai_field => :environment do
      raise "You have to specify a file path and a default namespace url. Example: rake iqvoc:idai_field_import FILE=... NAMESPACE_URL=..." unless ENV['FILE'] && ENV['NAMESPACE_URL']

      stdout_logger = Logger.new(STDOUT)
      stdout_logger.level = Logger::INFO

      importer = IdaiFieldImporter.new(File.new(ENV['FILE']), ENV['NAMESPACE_URL'], MultiLogger.new(stdout_logger, Rails.logger))
      importer.run
    end
  end
end
