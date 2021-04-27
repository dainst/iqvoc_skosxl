// EntitySelector extension for concept-selection
jQuery(document).ready(function($) {
  "use strict";


  var broader_path_info_for_suggestions = function (ev, item) {
  	var target_label = item.label;

		var responder = function(data, status, xhr) {
			var targetSuggestion = $('.tt-cursor:contains('+target_label+')');
			targetSuggestion.append("<small>" + data["broader_relations_string"] + "</small>")
			targetSuggestion.addClass('broader_path_added')
		}
		if(!$('.tt-cursor:first').hasClass('broader_path_added')) {
			var loc = window.location
			var current_language = loc.pathname.split("/")[1]
			var origin = item.value
			$.getJSON(loc.origin + "/" + current_language + "/concepts/" + origin + "/broader_path.json", responder);
		}
  }

  var broader_monos_input = $('#concept_relation_skos_broader_monos').parent().find('input.tt-input')[0];
  if (broader_monos_input) { $(broader_monos_input).bind("typeahead:cursorchanged", broader_path_info_for_suggestions); }

  var relation_skos_relateds_input = $('#concept_relation_skos_relateds').parent().find('input.tt-input')[0];
  if (relation_skos_relateds_input) { $(relation_skos_relateds_input).bind("typeahead:cursorchanged", broader_path_info_for_suggestions); }

  var search_filter_broader_concept = $('#search_filter_broader_concept').parent().find('input.tt-input')[0];
  if (search_filter_broader_concept) { $(search_filter_broader_concept).bind("typeahead:cursorchanged", broader_path_info_for_suggestions); }

	$('.match .concept-mapping-link').each(function(i, e){
    var match_target_url = new URL(e.href)
    if (match_target_url.origin == window.location.origin) {
      var current_language = window.location.pathname.split("/")[1]
      $.getJSON("/" + current_language + "/concepts" + match_target_url.pathname + "/broader_path.json", function(data, status, xhr) {
        e.innerText = data["broader_relations_string"]
      });
    }
	});
});

