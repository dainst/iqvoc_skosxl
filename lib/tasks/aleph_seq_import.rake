namespace :iqvoc do

  namespace :import do

    desc 'Imports AlephSeq data from a given url (URL=...) and an optional origin as parent for all concepts (ALL_IQVOC_PARENT_ORIGIN=...)'
    task :aleph_import => :environment do
      raise "You have to specify an url for the data file to be imported. Example: rake iqvoc:aleph_import:url URL=..." unless ENV['URL']

      stdout_logger = Logger.new(STDOUT)
      stdout_logger.level = Logger::INFO

      debug = true
      publish = true

      importer = AlephSeqImporter.new(ENV['URL'], MultiLogger.new(stdout_logger, Rails.logger), publish, debug, ENV['ALL_IQVOC_PARENT_ORIGIN'])
      importer.run
    end

  end

end
