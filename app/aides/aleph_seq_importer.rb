class AlephSeqImporter
  def initialize(object, logger = Rails.logger, publish = true, ignore_relations = false, parent_iqvoc_concept_for_all_origin = nil, ignore_languages = nil)
  	@file = case object
              when File
                File.open(object)
              when Array
                object
              else
                open(object)
            end
    @ignore_languages = ignore_languages
    @ignore_relations = ignore_relations
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
        aleph.push AlephObject.new(linebuffer, @publish, @logger, @ignore_languages) 
        linebuffer = Array.new
      end
    end

    @logger.info "Processing #{aleph.count} object from aleph export"

    unless @ignore_relations
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
  attr_reader :id, :ger, :broader_term, :concept, :label, :note, :cn, :eng, :fre, :pol
  def initialize(importlines, publish = false, logger, ign_lgns)
    @logger = logger
    @publish = publish
    for l in importlines
      if ger = l.match(/USE\s{3}L.*\$\$a(.*)\$\$9ger/) and !ign_lgns.include?("ger") then @ger = ger[1] end
      if eng = l.match(/USE\s{3}L.*\$\$a(.*)\$\$9eng/) and !ign_lgns.include?("eng") then @eng = eng[1] end
      if fre = l.match(/USE\s{3}L.*\$\$a(.*)\$\$9fre/) and !ign_lgns.include?("fre") then @fre = fre[1] end
      if pol = l.match(/USE\s{3}L.*\$\$a(.*)\$\$9pol/) and !ign_lgns.include?("pol") then @pol = pol[1] end
      
      if id = l.match(/([\d]*) FMT/) then @id = id[1] end
      if bt = l.match(/BT\s{4}L\s.*\$\$b(.*)\b/) then @broader_term = bt[1] end
      if cn = l.match(/CN\s{4}L\s.*\$\$a(.*)\b/) then @cn = cn[1] end
    end
    make_concept
  end

  private def find_labels
    labels = Array.new
    
    if @ger
      @ger_label = Label::SKOSXL::Base.where(value: @ger, language: "de").first 
      unless @ger_label
        @ger_label = Label::SKOSXL::Base.create(value: @ger, language: "de")
        @ger_label.published_at = Time.now if @publish
        @ger_label.save
      end
      labels << @ger_label
    end

    if @eng
      @eng_label = Label::SKOSXL::Base.where(value: @eng, language: "en").first 
      unless @eng_label
        @eng_label = Label::SKOSXL::Base.create(value: @eng, language: "en")
        @eng_label.published_at = Time.now if @publish
        @eng_label.save
      end
      labels << @eng_label
    end

    if @fre
      @fre_label = Label::SKOSXL::Base.where(value: @fre, language: "fr").first 
      unless @fre_label
        @fre_label = Label::SKOSXL::Base.create(value: @fre, language: "fr")
        @fre_label.published_at = Time.now if @publish
        @fre_label.save
      end
      labels << @fre_label
    end

    if @pol
      @pol_label = Label::SKOSXL::Base.where(value: @pol, language: "pl").first 
      unless @pol_label
        @pol_label = Label::SKOSXL::Base.create(value: @pol, language: "pl")
        @pol_label.published_at = Time.now if @publish
        @pol_label.save
      end
      labels << @pol_label
    end

    labels
  end

  private def make_concept
    return @concept if @concept
        
    if note = Note::SKOS::EditorialNote.where(value: "DAI14_ID_#{@id}").first
      if note.owner
        @logger.info "Concept with DAI14_ID_#{@id} already existing - REUSING & UPDATING"
        @concept = note.owner
      end 
    end
    @concept = Iqvoc::Concept.base_class.create() unless @concept 
    
    if ls = find_labels then @concept.pref_labels << ls end
    @concept.published_at = Time.now if @publish
    @concept.note_skos_editorial_notes << make_editorial_notes(@concept)
    @concept.save
  end

  private def make_editorial_notes(concept)
    notes = Array.new
    if @id and concept.notes.where(value: "DAI14_ID_#{@id}").none?
      notes.push Note::SKOS::EditorialNote.create(language: "de", value: "DAI14_ID_#{@id}", owner_type: concept.type, owner_id: concept.id)
    end
    if @cn and concept.notes.where(value: @cn).none?
      notes.push Note::SKOS::EditorialNote.create(language: "de", value: @cn, owner_type: concept.type, owner_id: concept.id)
    end
    return notes
  end
end