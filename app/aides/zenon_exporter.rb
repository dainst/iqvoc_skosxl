require 'iq_rdf'
require 'uri'
require 'fileutils'

class ZenonExporter
	include RdfHelper
	include Rails.application.routes.url_helpers
	include RdfNamespacesHelper
	include LabelsHelper

	def initialize(file_path, default_namespace_url, query, type, offset)
		default_url_options[:port] = URI.parse(default_namespace_url).port
		default_url_options[:host] = URI.parse(default_namespace_url).to_s.gsub(/\/$/, '')

		@query = query
		@offset = offset
		@type = type
		@file_path = file_path
		@logger = Rails.logger
		@document = IqRdf::Document.new
		@concepts = []
		@labels = []
		@notes = []
	end

	def run
		ActiveSupport.run_load_hooks(:rdf_export_before, self)
		
		add_namespaces(@document)
		
		if @type == "notes"
			add_notes_by_query(@document)
		
		end
		if @type == "labels"
			add_labels_by_query(@document)
		end
		
		ActiveSupport.run_load_hooks(:rdf_export_before_save, self)
		save_file(@file_path, "xml", @document)
	end

	
	def add_skos_xl_labels(document)
		for c in @concepts
			c.labels.each do |label|
				render_label_rdf(document, label)
			end
		end
	end

	def add_namespaces(document)
		RdfNamespacesHelper.instance_methods.each do |meth|
			namespaces = send(meth)
			document.namespaces(namespaces) if namespaces.is_a?(Hash)
		end
	end

	private
		def add_notes_by_query(document)
			@notes = Note::SKOS::EditorialNote.order('id').limit(1000).offset(@offset).where(value: @query)
			return if @notes.size == 0

			@notes.each do |note|
				concept = note.concept
				unless @concepts.include?(concept)
					@concepts << concept
					## LABELS WERDEN SPAETER NACH HOOK GERENDERED
					render_concept(document, concept, true)
				end
			end
		end

		def add_labels_by_query(document)
			labels = Iqvoc::XLLabel.base_class.published.order('id').limit(1000).offset(@offset).where("value LIKE '%#{@query}%'")
			return if labels.size == 0


			labels.each do |label|
				label.concepts.each do |concept|
					unless @concepts.include?(concept)
						@concepts << concept
						## LABELS WERDEN SPAETER NACH HOOK GERENDERED
						render_concept(document, concept, true)
					end
				end
			end
		end

		def save_file(file_path, type, content)
			begin
				@logger.info "Saving export to '#{@file_path}'"
				create_directory(@file_path)
				file = File.open(@file_path, 'w')
				content = serialize_rdf(content, type)
				file.write(content)
			rescue IOError => e
				# some error occur  e.g not writable
			ensure
				file.close unless file == nil
			end
		end

		def create_directory(file_path)
			dirname = File.dirname(file_path)
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end
		end

		def serialize_rdf(document, type)
				document.to_xml
		end
end