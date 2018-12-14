require "csv"
class SkosCsvImporter
	def initialize(abs_path, root_concept_origin)
		@root_concept = Iqvoc::Concept.base_class.find_by_origin root_concept_origin

		csv_text = File.read(abs_path)
		csv = CSV.parse(csv_text, :headers => true, :col_sep => ';')
		i = 0
		csv.each do |row|
			@current_concept = Concept::SKOS::Base.create()
			@current_concept.broader_relations

			row.each  do |column| 
				# COLUMN HEADERS encode relation to created concept:
				# type:AltLabel,language:de (types: PrefLabel, AltLabel, HistoryNote, Definition)

				value = column[1]
				next if (value == "" || value == nil)
				
				header = header_to_hash(column[0])
				
				if header["type"] == "PrefLabel"
					label = Label::SKOSXL::Base.create(value: value, language: header["language"], published_at: Time.now) unless label = find_existing_label(value, header["language"])
					@current_concept.pref_labelings.create(target: label)
				end

				if header["type"] == "AltLabel"
					label = Label::SKOSXL::Base.create(value: value, language: header["language"], published_at: Time.now) unless label = find_existing_label(value, header["language"])
					@current_concept.alt_labelings.create(target: label)
				end

				if header["type"] == "HistoryNote"
					note = Note::SKOS::HistoryNote.create(value: value, language: header["language"], owner_type:"Concept::Base")
					@current_concept.note_skos_history_notes << note
				end

				if header["type"] == "Definition"
					definition = Note::SKOS::Definition.create(value: value, language: header["language"], owner_type:"Concept::Base")
					@current_concept.note_skos_definitions << definition
				end
			end

			if @root_concept
				@current_concept.broader_relations.create_with_reverse_relation(@root_concept)
			end
			@current_concept.published_at = Time.now
			@current_concept.save()

		end
	end

	def header_to_hash(str)
		Hash[
			str.split(',').map do |pair|
				k, v = pair.split(':', 2)
		    	[k, v]
		    end
	 	]
	end

	def find_existing_label(label_value, language)
		Iqvoc::XLLabel.base_class.where(language: language, value: label_value).first
	end
end