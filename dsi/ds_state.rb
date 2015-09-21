require_relative "ds_templates"

# Runtime states ####################################################################################################
# These objects know about the template classes, but the template classes don't know about them.
# The runtime is responsible for its own setup based on the contexts.
# Or is it better for dsc for this code to do the setup work for the template classes after all?

class DsiRuntimeState
	def initialize(currentScopeName, values)
		@currentScopeName = currentScopeName
		@values = values
		@returnValue # 
	end
end

class DsiGlobalContext
	def initialize(globalTemplate)
		@globalTemplate = globalTemplate
		@state = DsiRuntimeState.new
		
		# Load variables
		@variables = Array.new
	end
	
	def run
		main = @globalTemplate.getFunctionTemplate("main")
		if not main == nil
			params = Array.new
			ret = main.evaluate(params, @state)
		end
	end
end