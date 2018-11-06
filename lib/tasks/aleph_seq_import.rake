namespace :iqvoc do

  namespace :import do

    desc 'Imports AlephSeq data from a given url (URL=...) and a mandatory flag for relations processing (IGNORE_RELATIONS=true/false) and an optional origin as parent for all concepts (ALL_IQVOC_PARENT_ORIGIN=...) and optional comma separated languages to ignore (IGNORE_LANGUAGES=ger,eng,fre,pol)'
    task :aleph_import => :environment do
      raise "You have to specify an url for the data file to be imported. Example: rake iqvoc:aleph_import:url URL=... IGNORE_RELATIONS=false" unless ENV['URL']

      stdout_logger = Logger.new(STDOUT)
      stdout_logger.level = Logger::INFO

      publish = true
      ignore_relations ||= (ENV['IGNORE_RELATIONS'] == "true")
      ignore_laguages ||= ENV['IGNORE_LANGUAGES'].split(",")

      importer = AlephSeqImporter.new(ENV['URL'], MultiLogger.new(stdout_logger, Rails.logger), publish, ignore_relations, ENV['ALL_IQVOC_PARENT_ORIGIN'], ignore_laguages)
      importer.run
    end

  end

end
