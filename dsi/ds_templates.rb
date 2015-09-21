require 'set'
#require_relative "ds_state"

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
	def initialize(vars, enums, classTemplates, functionTemplates)
		debugTemplate "DsiGlobalTemplate"
		super("0_GLOBAL_CONTEXT")
		@vars = Array.new
		@enums = Array.new
		@classTemplates = classTemplates
		@functionTemplates = functionTemplates
	end
	
	def getVars
		@vars
	end
	
	def getClassTemplates
		@classes
	end
	
	def getClassTemplate(name)
		@classTemplates.each do |c|
			if f.getName.eql?(name)
				return c
			end
		end
		return nil
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
		@className = nil
	end

	def getName
		@name
	end
	
	def setClassName(className)
		@className = className
	end
	
	def setInstructions(instructions)
		@instructions = instructions
	end
end

# DsiVariableName ####################################################################################################

class DsiVariableNanme
	def initialize(name)
		debugTemplate "DsiVariableNanme #{name}"
		@name = name
		@value = nil
	end
	def setValue(value)
		@value = value
	end
	def getName
		@name
	end
	def getValue
		@value
	end
end
