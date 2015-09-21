require_relative "ds_templates"

class DsiRunState
	def initialize(currentScopeName, values)
		@currentScopeName = currentScopeName
		@values = values
		@returnValue # 
	end
end

class DsiGlobalContext
	def initialize(globalTemplate)
		@globalTemplate = globalTemplate
		
		# load variables
		main = globalTemplate.getFunctionTemplate("main")
		if not main == nil
			params = Array.new
			ret = main.evaluate(params, state)
		end
	end
end