require 'set'
require_relative "ds_state"

$verboseTemplate = true

def debugTemplate text
	puts text if $verboseTemplate
end

# DsiTemplate ####################################################################################################

class DsiStateTemplate
	def initialize(name)
		debugTemplate "DsiTemplate #{name}"
		@valid = true
		@name = name
	end
	
	def isValid
		@valid
	end
	
	def invalidate
		@valid = false
	end
	
	def evaluate(params, state)
	end
end

# DsiGlobalTemplate ####################################################################################################

class DsiGlobalTemplate < DsiStateTemplate
	# Allowed in the global template are use, variable declaration, enum declaration, class declaration, function declaration
	def initialize
		debugTemplate "DsiGlobalTemplate"
		super("0_GLOBAL_CONTEXT")
		@uses = Set.new
		@vars = Set.new
		@enums = Array.new
		@classes = Array.new
		@functionTemplates = Array.new
	end
	
	def getClassTemplates
		@classes
	end
	
	def getFunctionTemplates
		@functionTemplates
	end
	
	def getFunctionTemplate(name)
		@functionTemplates.each do |f|
			if f.getName.eql?(name)
				return f
			end
		end
		return nil
	end
		

	def addUse(name)
		@uses.add(name)
	end
	
	def addVar(name)
		@vars.add(name)
	end
	
	def addEnum(name, values)
		enum = DsiEnum.new(name, values)
		@enums.each do |e|
			if e.getName.eql?(name)
				return
			end
		end
		@enums.add(enum)
	end
	
	def addClass(classTemplate)
		@classes.each do |c|
			if c.getName.eql?(classTemplate.getName)
				return
			end
		end
		@classes.push(classTemplate)
	end

	def addFunction(functionTemplate)
		@functionTemplates.each do |f|
			if f.getName.eql?(functionTemplate.getName)
				return
			end
		end
		@functionTemplates.push(functionTemplate)
	end
end

# DsiClassTemplate ####################################################################################################

class DsiClassTemplate < DsiStateTemplate
	def initialize(name, baseClass, vars, functionTemplates)
		debugTemplate "DsiClassTemplate #{name} #{baseClass}"
		super(name)
		@baseClass = baseClass
		@vars = vars
		@functionTemplates = functionTemplates
	end
	
	def getName
		@name
	end
	
	def addVar(name)
		@vars.add(name)
	end
	
	def addFunction(functionTemplate)
		# TODO: Qualify incoming names (classname.functionname)
		@functionTemplates.each do |f|
			if f.getName.eql?(functionTemplate.getName)
				return
			end
		end
		@functionTemplates.push(functionTemplate)
	end
end	

# DsiFunctionTemplate ####################################################################################################

class DsiFunctionTemplate < DsiStateTemplate
	def initialize(name, paramNames, vars, instructions)
		debugTemplate "DsiFunctionTemplate #{name}"
		super(name) # TODO: Scope
		@paramNames = paramNames
		@vars = vars
		@instructions = instructions
	end

	def getName
		@name
	end
	
	def setInstructions(instructions)
		@instructions = instructions
	end
end


# DsiVariable ####################################################################################################

class DsiTemplateVariable
	def initialize(name, value)
		debugTemplate "DsiTemplateVariable #{name}"
		@name = name
		@value = value
	end
end

class DsiTemplateVariableList
	def initialize(constants, variables)
		debugTemplate "DsiTemplateVariableList"
		@constants = constants
		@variables = variables
	end
end

