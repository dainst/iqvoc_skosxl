require "csv"
class SimpleImporter
	def initialize(abs_path)

		csv_text = File.read(abs_path)
		csv = CSV.parse(csv_text, :headers => true, :col_sep => ';')
		i = 0

		csv.each do |row|
			next if row["preflabel"].blank?

			concept = Concept::SKOS::Base.create()

			parent_c = Iqvoc::Concept.base_class.find_by_origin(row["parent_id"])
			
			unless parent_c
				concept.destroy
				next
			end

			value = row["preflabel"]
			label = Label::SKOSXL::Base.create(value: value, language: "de", published_at: Time.now) unless label = find_existing_label(value, "de")
			concept.pref_labels << label

			if parent_c
				concept.broader_relations.create_with_reverse_relation(parent_c)
			end

			unless row["exact_match_id"].blank?
				match_target = Iqvoc::Concept.base_class.find_by_origin(row["exact_match_id"])
				
				concept.match_skos_exact_matches.create(value: "http://thesauri.dainst.org/"+row["exact_match_id"])

			end


			concept.published_at = Time.now
			concept.save()
		end
	end

	def find_existing_label(label_value, language)
		Iqvoc::XLLabel.base_class.where(language: language, value: label_value).first
	end
end