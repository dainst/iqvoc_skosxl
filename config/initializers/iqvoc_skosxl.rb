require 'iqvoc/xllabel'
module Iqvoc
	module Configuration
		module Core
		 	module ClassMethods
		  		def routing_constraint
		          lambda do |params, req|
		            langs = Iqvoc::Concept.pref_labeling_languages.join('|').presence || 'en'
		            return params[:lang].to_s =~ /^(#{langs})$/
		          end
		        end
		    end
		end
	end
end