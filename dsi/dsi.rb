###
#
# DSI - dScript Interpreter
# author: mghansen@gmail.com
#
###

require_relative 'ds_loader'
require_relative 'ds_templates'
require_relative 'ds_instructions'

# Main ============================================================

def dsiMain

	if ARGV.size < 1
		puts "Usage: dsi <filename>"
		return
	end
	
	loader = Loader.new()
	loader.loadFile("#{ARGV[0]}")
	
	template = loader.getGlobalTemplate
	template.run

end

dsiMain

=begin

Dsi classes are getting a little out of hand. Here's the hierarchy (9/20):

ds_runtime

	class DsiInstruction (DsiInstruction's evaluate() method will be called as code runs)
		class DsiAssignment < DsiInstruction
			@lValue = lValue
			@operator = operator
			@rValue = rValue
		class DsiIf < DsiInstruction
			@conditions = conditions
		class DsiCondition < DsiInstruction
			@conditionType = conditionType
			@expression = expression
			@statements = statements
		class DsiForIn < DsiInstruction
			@variant = variant
			@set = set
			@statements = statements
		class DsiForFrom < DsiInstruction
			@variant = variant
			@startExpression = startExpression
			@endExpression = endExpression
			@statements = statement
		class DsiWhile < DsiInstruction
			@expression = expression
			@statements = statements
		class DsiDo < DsiInstruction
			@statements = statements
			@expression = expression
		class DsiSwitch < DsiInstruction
			@expression = expression
			@cases = cases
			class DsiCase
				@expression = expression
				@statements = statements
		class DsiExpression < DsiInstruction
			class DsiOperation < DsiExpression
				@leftExpression = leftExpression
				@operator = operator
				@rightExpression = rightExpression
			class DsiFunctionCall < DsiExpression
				@name = name
				@paramExpressions = paramExpressions
			class DsiValue < DsiExpression 
					(Value holds the actual value. The template will create a list of these.)
					(Constants will be created as normal values in the global context on start.)
				@value = value
				class DsiNumberValue < DsiValue
				class DsiStringValue < DsiValue
				class DsiBoolValue < DsiValue
				class DsiEnumValue < DsiValue
				class DsiFunctionReferenceValue < DsiValue
				class DsiClassValue < DsiValue
			class DsiVariable < DsiExpression (Doesn't store the value. It's just a reference to the name.)
				@name = name
				class DsiConstantVariable < DsiVariable
					@value = value

ds_templates.rb

	class DsiStateTemplate
		@valid = true
		@name = name
		class DsiGlobalTemplate < DsiStateTemplate
			@uses = Set.new
			@vars = Set.new
			@enums = Array.new
			@classes = Array.new
			@functionTemplates = Array.new
		class DsiClassTemplate < DsiStateTemplate
			@baseClass = baseClass
			@vars = vars
			@functionTemplates = functionTemplates
		class DsiFunctionTemplate < DsiStateTemplate
			@paramNames = paramNames
			@vars = vars
			@instructions = instructions
	class DsiTemplateVariable
		@name = name
		@value = value (DsiValue)

=end