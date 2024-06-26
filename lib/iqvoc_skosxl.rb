module IqvocSKOSXL
  unless Iqvoc.const_defined?(:SKOSXL) && Iqvoc::SKOSXL.const_defined?(:Application)
    require File.join(File.dirname(__FILE__), '../config/engine')
  end

  ActiveSupport.on_load(:after_iqvoc_config) do
    require 'iqvoc'

    Iqvoc.config do |cfg|
      prefix = 'languages.further_labelings.'
      cfg.deregister_setting("#{prefix}Labeling::SKOS::AltLabel") # iQvoc core default
      cfg.register_settings({
        'title' => 'iQvoc SKOS-XL',
        "#{prefix}Labeling::SKOSXL::AltLabel" => ['en', 'de']
      })
    end

    unless Iqvoc.rdf_namespaces[:skosxl]
      Iqvoc.rdf_namespaces[:skosxl] = 'http://www.w3.org/2008/05/skos-xl#'
    end

    Iqvoc::Concept.include_module_names << 'Concept::SKOSXL::Extension'
    Iqvoc::Concept.pref_labeling_class_name = 'Labeling::SKOSXL::PrefLabel'
    Iqvoc::Concept.alt_labeling_class_name = 'Labeling::SKOSXL::AltLabel'

    Iqvoc::Collection.include_module_names << 'Collection::SKOSXL::Extension'

    # TODO
    # Iqvoc.searchable_class_names = Iqvoc::Concept.labeling_class_names.keys +
    #    Iqvoc::Concept.note_class_names

    Iqvoc.navigation_items.last[:items] << {
      text: "Über iDAI.thesauri",
      href: proc { about_idai_thesauri_path },
      controller: 'about',
      action: 'about_idai_thesauri'
    }
  end
end
