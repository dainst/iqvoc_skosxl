class VocabImporter
	def initialize(abs_path)
		concepts_rdf = Nokogiri::XML(File.open(abs_path)).xpath("/rdf:RDF/skos:Concept")		
		concepts_rdf.each do |concept| 
		# german labels
			german_label_value = concept.xpath("skos:prefLabel[@xml:lang='de']").text
			next if german_label_value.blank? 
			 
		# add german label
			current_concept = Concept::SKOS::Base.create()
		
		 # VOCAB-URL as editional note
			current_concept.note_skos_editorial_notes << Note::SKOS::EditorialNote.create(value: concept.attributes["about"].value, language: "de", owner_type:"Concept::Base")
			current_concept.pref_labelings.create(target: find_existing_label_or_create(german_label_value, "de"))
		
		# german alternate labels
			concept.xpath("skos:altLabel[@xml:lang='de']").each do |alt_label_rdf|
				german_alt_label_value = alt_label_rdf.text
				current_concept.alt_labelings.create(target: find_existing_label_or_create(german_alt_label_value, "de"))
			end
			
		# translations - if more than one per language it gets saved as alt-label
			concept.xpath("skos:exactMatch/skos:Concept/skos:prefLabel").each do |label_rdf|
				lang = label_rdf.attributes["lang"].value
				value = label_rdf.text
				translation_label = find_existing_label_or_create(value, lang)
				if current_concept.pref_labels.where(language: lang).count == 0
					current_concept.pref_labelings.create(target: translation_label)
				else
					current_concept.alt_labelings.create(target: translation_label)
				end
			end

		# Notes
			concept.xpath("skos:scopeNote").each do |note_rdf|
				lang = note_rdf.attributes["lang"].value
				value = note_rdf.text
				current_concept.note_skos_editorial_notes << Note::SKOS::EditorialNote.create(value: value, language: lang, owner_type:"Concept::Base")
			end
	
		#getty
			concept.xpath("skos:exactMatch/skos:Concept[contains(@rdf:about,'getty')]").each do |getty_match|
				getty_link = getty_match.values.first
				begin
					remotefile = open(getty_link + ".rdf")
					remote_rdf  = Nokogiri::XML(File.open(remotefile.path)) 
					if english_pref_label =  remote_rdf.xpath("//skos:prefLabel[@xml:lang=\"en\"]").first
						current_concept.note_skos_examples << Note::SKOS::Example.create(language: "en", value: getty_link + " (" + english_pref_label.text + ")" , owner_type: "Concept::Base")
					end
				rescue
					puts "Error - could not load getty resource - URL: getty_link + ".rdf""
				end
			end

			current_concept.published_at = Time.now
			current_concept.save()
		end	

	# Relations
		concepts_rdf.each do |rdf_concept|
			if concept_note = Note::SKOS::EditorialNote.where(value: rdf_concept.attributes["about"].value).first
				if concept = concept_note.owner
					if broader = rdf_concept.xpath("skos:broader").first
						broader_url = broader.attributes["resource"].value

						if note = Note::SKOS::EditorialNote.where(value: broader_url).first
							if broader_concept = note.owner
								concept.broader_relations.create_with_reverse_relation(broader_concept)
							else
								puts "Error - Connecting broader concept - EditorialNote found, but it has to owner "
							end
						else
							puts "Error - Connecting broader concept - No EditorialNote with vocab-url of broader concept found"
						end
					end
				end
			end
		end
	end

	def find_existing_label_or_create(label_value, language)
		label = Iqvoc::XLLabel.base_class.where(language: language, value: label_value).first
		unless label = find_existing_label(label_value, language)
			label = Label::SKOSXL::Base.create(
				value: label_value, language: language, published_at: Time.now) 
		end
		return label
	end

	def find_existing_label(label_value, language)
		Iqvoc::XLLabel.base_class.where(language: language, value: label_value).first
	end
end