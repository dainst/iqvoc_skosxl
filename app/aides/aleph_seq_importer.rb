class AlephSeqImporter
  def initialize(object, logger = Rails.logger, publish = true, verbose = false, parent_iqvoc_concept_for_all_origin = nil)
  	@file = case object
              when File
                File.open(object)
              when Array
                object
              else
                open(object)
            end

    @parent_iqvoc_concept_for_all_origin = parent_iqvoc_concept_for_all_origin
    @publish = publish
    @logger = logger

    raise "AlephSeqImporter#import: Parameter 'file' should be aleph_object File or an Array." unless (@file.is_a?(File) || @file.is_a?(Array))
  end

  def run
    aleph = Array.new
    @logger.info "publish: '#{@publish}'"
    @logger.info "Origin of parent for all imported concepts #{@parent_iqvoc_concept_for_all_origin}"
    linebuffer = Array.new

    @file.each_with_index do |line, index|
      linebuffer.push line 
      if line.include? "LDR"
        aleph.push AlephObject.new(linebuffer, @publish, @logger) 
        linebuffer = Array.new
      end
    end

    @logger.info "Processing #{aleph.count} object from aleph export"

    if @parent_iqvoc_concept_for_all_origin 
      @parent_iqvoc_concept_for_all = Iqvoc::Concept.base_class.find_by_origin(@parent_iqvoc_concept_for_all_origin)
      unless @parent_iqvoc_concept_for_all
        @logger.info "Fatal: could not find parent_iqvoc_concept_for_all"
        exit
      end
    end

    unless @parent_iqvoc_concept_for_all
      # making parents from broader_term ids from aleph
      for aleph_object in aleph
        next unless aleph_object.broader_term 
        set_borader_term_by_dai14_id(aleph_object)
      end
    else
      # setting same parent for all 
      for aleph_object in aleph
        aleph_object.concept.broader_relations.create_with_reverse_relation(@parent_iqvoc_concept_for_all)
      end
    end
  end

  def set_borader_term_by_dai14_id aleph_object
    broader_term_concept_note = Note::SKOS::EditorialNote.where(value: "DAI14_ID_#{aleph_object.broader_term}").first
    

    if broader_term_concept = broader_term_concept_note.owner
      if aleph_object.concept 
        aleph_object.concept.broader_relations.create_with_reverse_relation(broader_term_concept)
      else
        @logger.info "No Concept for #{aleph_object.id} found"
      end
    else
      @logger.info "No broader_term_concept for #{aleph_object.id}"
    end
  end
end



class AlephObject
  attr_reader :id, :ger, :broader_term, :concept, :label, :note, :cn
  def initialize(importlines, publish = false, logger)
    @logger = logger
    @publish = publish
    for l in importlines
      if ger = l.match(/USE\s{3}L.*\$\$a(.*)\$\$9ger/) then @ger = ger[1] end
      if id = l.match(/([\d]*) FMT/) then @id = id[1] end
      if bt = l.match(/BT\s{4}L\s.*\$\$b(.*)\b/) then @broader_term = bt[1] end
      if cn = l.match(/CN\s{4}L\s.*\$\$a(.*)\b/) then @cn = cn[1] end
    end
    make_concept
  end

  private def find_label
    return unless @ger
    @label = Label::SKOSXL::Base.where(value: @ger, language: "de").first 
    if @label
      return @label
    end
    @label = Label::SKOSXL::Base.create(value: @ger, language: "de")
    @label.published_at = Time.now if @publish
    @label.save
    @label
  end

  private def make_concept
    return @concept if @concept
        
    if note = Note::SKOS::EditorialNote.where(value: "DAI14_ID_#{@id}").first
      if note.owner
        @logger.info "ERROR Concept with DAI14_ID_#{@id} already existing"
        @logger.info note
        return
      end 
    end
    @concept = Iqvoc::Concept.base_class.create()
    
    if l = find_label then @concept.pref_labels << l end
    @concept.published_at = Time.now if @publish
    @concept.note_skos_editorial_notes << make_editorial_notes(@concept)
    @concept.save
  end

  private def make_editorial_notes(concept)
    notes = Array.new
    if @id
      notes.push Note::SKOS::EditorialNote.create(language: "de", value: "DAI14_ID_#{@id}", owner_type: concept.type, owner_id: concept.id)
    end
    if @cn
      notes.push Note::SKOS::EditorialNote.create(language: "de", value: @cn, owner_type: concept.type, owner_id: concept.id)
    end
    return notes
  end
end