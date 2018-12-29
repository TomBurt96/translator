#!/usr/bin/ruby
load 'scanner.rb'
#parser class, does the parsing
class Parser
	#first production of the grammar. Checks for any starting meta_statements, then calls program_tail production
	def program
		if(meta_statement)
			program
		else
			program_tail
		end
	end

#production that get 
	def program_tail
		if(@s.peek[0,3] == "int" || @s.peek[0,4] == "void")
			t = type_name
			@output.push(t)
			temp = identifier
			data_or_func(temp)
			program_tail
		end
	end

	def data_or_func(ident)
		if(@s.peekChar == "," || @s.peekChar == ";")
			beginning_data_decls(ident)
			@s.matchChar(';')
		elsif(@s.peekChar == "(")
			@output.push(ident)
			start_func
		end
	end

	def beginning_data_decls(ident)
		@symTable[ident] = getGlobal
		if(@s.peekChar == ',')
			@s.matchChar(',')
			id_list("global")
		end
		@output.push("global[" + @global_var_counter.to_s + "];\n")
		@backupTable.update(@symTable)
	end

	def start_func
		@s.matchChar("(")
		@output.push("(")
		parameter_list
		@s.matchChar(")")
		@output.push(")")
		func_follow
		func_list
	end

	def func_list
		if(@s.peek[0,3] == "int" || @s.peek[0,4] == "void")
			func
			func_list
		end
	end	

	def func
		@var_counter = 0
		refreshTable
		func_decl
		func_follow
	end

	def func_decl
		@output.push(type_name)
		@output.push(identifier)
		@s.matchChar("(")
		@output.push("(")
		parameter_list
		@s.matchChar(")")
		@output.push(")")
	end

	def func_follow
		if(@s.peekChar == ";")
			@s.matchChar(";")
			@output.push(";\n")
		elsif(@s.peekChar == "{")
			@func_counter += 1
			@s.matchChar("{")
			@output.push("{\n")
			tempData = data_decls
			tempStatements = statements
			@output.push("int ")
			@output.push(getLocal())
			@output.push(";\n")
			@output.concat(@tempO)
			@tempO = Array.new
			@s.matchChar("}")
			@output.push("}\n")
		else
			raise "Error"
		end			
	end

	def parameter_list
		if(@s.peek[0,4] == "void" || @s.peek[0,3] == "int")
			@output.push(type_name)
			parameter_list_tail
		end
	end

	def parameter_list_tail
		if(@alph.has_key?(@s.peekChar))
			identTemp = identifier
			@output.push(identTemp)
			non_empty_list
		end
	end

	def non_empty_list
		@s.checkSpace
		if(@s.peekChar == ",")
			@s.matchChar(",")
			@output.push(", ")
			@output.push(type_name)
			identTemp = identifier
			@output.push(identTemp)
			non_empty_list
		end
	end

	def data_decls
		if(@s.peek[0,3] == "int" || @s.peek[0,4] == "void")
			@declaration = true
			type_name
			id_list("local")
			@s.matchChar(";")
			data_decls
		end
	end

	def type_name
		if(@s.peek[0,4] == "void")
			@s.match("void")
			return "void "
		elsif(@s.peek[0,3] == "int")
			@s.match("int")
			return "int "
		else
			raise "Error"
		end
	end

	def id_list(section)
		arrayName = ""
		if(section == "global")
			arrayName = getGlobal
		else
			arrayName = getLocal
		end
		@symTable[identifier] = arrayName
		id_list_tail(section)
	end

	def id_list_tail(section)
		if(@s.peekChar == ",")
			@s.matchChar(",")
			arrayName = ""
			if(section == "global")
				arrayName = getGlobal
			else
				arrayName = getLocal
			end
			@symTable[identifier] = arrayName
			id_list_tail(section)
		end
	end

	def statements
		@s.checkLine
		if(@alph.has_key?(@s.peekChar) || @s.peekChar == '#' || @s.peekChar == '<')
			@statement_counter += 1
			statement
			statements
		end
	end

	def statement
		@tempO.push("  ")
		if(@s.peek[0, 6] == "printf")
			print_func_call
		elsif(@s.peek[0,5] == "scanf")
			scan_func_call
		elsif(@s.peek[0,2] == "if")
			if_statement
		elsif(@s.peek[0,5] == "while")
			while_statement
		elsif(@s.peek[0,6] == "return")
			return_statement
		elsif(@s.peek[0,5] == "break")
			break_statement
		elsif(@s.peek[0,8] == "continue")
			continue_statement
		elsif(@alph.has_key?(@s.peekChar) && @s.peekChar != "_")
			exp_statement
		elsif(metastatement)

		else
			raise "Error"
		end
	end

	def exp_statement
		varname = identifier
		func_or_dec = @s.peekChar
		local = varname
		if(@s.peekChar == "=")
			if(@symTable[varname] == nil)
				local = getLocal
				@symTable[varname] = local
			else
				local = @symTable[varname]
			end
		end
		temp = assign_or_func
		@tempO.push(local+temp)
	end

	def assign_or_func
		if(@s.peekChar == "=")
			@s.matchChar("=")
			@s.checkSpace
			temp = expression
			@s.matchChar(";")
			return " = "+temp+";\n"
		elsif(@s.peekChar == "(")
			@s.matchChar("(")
			@s.checkSpace
			exprTemp = expr_list
			@s.checkSpace
			@s.matchChar(")")
			@s.matchChar(';')
			return "("+exprTemp+");\n"
		else
			raise "Error"
		end
	end

	def print_func_call
		@s.match("printf")
		@s.matchChar("(")
		@tempO.push("printf(")
		str
		printf_tail
	end

	def printf_tail
		if(@s.peekChar == ")")
			@s.matchChar(")")
			@s.matchChar(';')
			@tempO.push(");\n")
		elsif(@s.peekChar == ",")
			@s.matchChar(",")
			temp = expression
			@s.matchChar(")")
			@s.matchChar(';')
			@tempO.push(", "+temp)
			@tempO.push(");\n")
		else
			raise "Error"
		end
	end

	def scan_func_call
		@s.match("scanf")
		@s.matchChar("(")
		@tempO.push("scanf(")
		@tempO.push(str)
		@s.matchChar(",")
		@s.matchChar("&")
		@tempO.push(", &")
		temp = expression
		@s.matchChar(")")
		@s.matchChar(';')
		@tempO.push(temp>>");\n")
	end

	def expr_list
		l = ""
		if(@alph.has_key?(@s.peekChar) || @dig.has_key?(@s.peekChar))
			l = non_empty_expr_list
		end
		return l
	end

	def non_empty_expr_list
		exprTemp = expression
		temp = expr_list_tail
		return exprTemp+temp
	end

	def expr_list_tail
		l = ""
		if(@s.peekChar == ",")
			@s.matchChar(",")
			exprTemp = expression
			exprlistTemp = expr_list_tail
			l = ","+exprTemp+exprlistTemp
		end
		return l
	end

	def if_statement
		@s.match("if")
		@s.matchChar("(")
		tempCond = condition_expression
		@s.matchChar(")")
		if_label = generateLabel
		else_label = generateLabel
		@tempO.push(tempCond)
		@tempO.push(")goto " + if_label + ";\n")
		@tempO.push("goto " + else_label + ";\n")
		@tempO.push(if_label + ":;\n")
		block_statements
		else_statement(else_label)
	end

	def else_statement(else_label)
		@tempO.push(else_label + ":;\n")
		if(@s.peek[0,4] == "else")
			@s.match("else")
			block_statements
		end
	end

	def while_statement
		while_label = generateLabel
		@continue_label = while_label
		@s.match("while")
		@s.matchChar("(")
		condTemp = condition_expression
		@s.matchChar(")")
		@tempO.push("goto " + while_label + ";\n")
		@tempO.push(while_label + ":;\n")
		block_statements
		@tempO.push(condTemp + ") goto " + while_label + ";\n")
		if(@is_break == true)
			@tempO.push(@break_label + ":;\n")
			@is_break = false
			@break_label = ""
		end
	end

	def return_statement
		@s.match("return")
		return_tail
	end

	def return_tail
		if(@alph.has_key?(@s.peekChar) || @dig.has_key?(@s.peekChar) || @s.peekChar == '(' || @s.peekChar == '-')
			temp = expression
			@s.matchChar(";")
			@tempO.push("return " + temp + ";\n")
		elsif(@s.peekChar == ';')
			@s.matchChar(';')
			@tempO.push("return;\n")
		else
			raise "Error"
		end
	end

	def break_statement
		@s.match("break")
		@s.matchChar(';')
		@break_label = generateLabel
		@is_break = true
		@tempO.push("goto " + @break_label + ";\n")
	end

	def continue_statement
		@s.match("continue")
		@s.matchChar(';')
		@tempO.push("goto " + @continue_label + ";\n")
	end

	def block_statements
		@s.matchChar('{')
		statements
		@s.matchChar('}')
	end

	def condition_expression
		condTemp = condition
		tailTemp = condition_expression_tail
		return "if("+condTemp+tailTemp
	end

	def condition_expression_tail
		if(@s.peekChar == '&' || @s.peekChar == '|')
			opTemp = condition_op
			condTemp = condition
			tailTemp = condition_expression_tail
			return opTemp+condTemp+tailTemp
		end
		return ""
	end

	def condition_op
		if(@s.peek[0,2] == "&&")
			@s.match("&&")
			return " && "
		elsif(@s.peek[0,2] == "||")
			@s.match("||")
			return " || "
		else
			raise "Error"
		end
		return nil
	end

	def condition
		temp1 = expression
		optemp = comparison_op
		temp2 = expression
		return temp1+optemp+temp2
	end
#comparison operator production
	def comparison_op
		if(@s.peek[0,2] == "==")
			@s.match("==")
			return "=="
		elsif(@s.peekChar == '!')
			@s.match("!=")
			return "!="
		elsif(@s.peekChar == '>')
			@s.matchChar('>')
			return ">" + inequality_tail
		elsif(@s.peekChar == '<')
			@s.matchChar('<')
			return "<" + inequality_tail
		else
			raise "Error"
		end
	end

	def inequality_tail
		temp = ""
		if(@s.peekChar == '=')
			@s.matchChar('=')
			temp = "="
		end
		return temp
	end

	def expression
		termTemp = term
		exprTemp = expression_tail(termTemp)
		return exprTemp
	end

	def expression_tail(nam)
		if(@s.peekChar == '+' || @s.peekChar == '-')
			a = addop
			termTemp = term
			local = getLocal
			@tempO.push(local + " = " + nam + a + termTemp + ";\n")
			return expression_tail(local)
		end
		return nam
	end

	def addop
		temp = ""
		if(@s.peekChar == '+')
			temp = " + "
			@s.matchChar('+')
		elsif(@s.peekChar == '-')
			temp = " - "
			@s.matchChar('-')
		else
			raise "Error"
		end
		return temp
	end

	def term
		factTemp = factor
		temp = term_tail(factTemp)
		return temp
	end

	def term_tail(nam)
		if(@s.peekChar == '*' || @s.peekChar == '/')
			m = mulop
			factTemp = factor
			local = getLocal
			@tempO.push(local + " = " + nam + m + factTemp + ";\n")
			return term_tail(local)
		end
		return nam
	end

	def mulop
		temp = ""
		if(@s.peekChar == '*')
			@s.matchChar('*')
			temp = " * "
		elsif(@s.peekChar == '/')
			@s.matchChar('/')
			temp = " / "
		else
			raise "Error"
		end
		return temp
	end

	def factor
		if(@alph.has_key?(@s.peekChar))
			varName = identifier
			temp = factor_tail
			if(@symTable.has_key?(varName))
				n = @symTable[varName]
				return n
			elsif (temp != "")
				return varName+temp
			else
				local = getLocal()
				@symTable[varName] = local
				@tempO.push(local + " = " + varName + temp + ";\n")
				return local
			end
		elsif(@dig.has_key?(@s.peekChar))
			return number
		elsif(@s.peekChar == '-')
			@s.matchChar('-')
			num = number
			local = getLocal
			@tempO.push(local + " = -" + num + ";\n")
			return local
		elsif(@s.peekChar == '(')
			@s.matchChar('(')
			exprTemp = expression
			@s.matchChar(')')
			return exprTemp
		else
			puts "this: " + @s.peekChar
			raise "Error"
		end
		return nil
	end

	def factor_tail
		t = ""
		if(@s.peekChar == '(')
			@s.matchChar('(')
			expTemp = expr_list
			@s.matchChar(')')
			t = "("+expTemp+")"
		elsif(@s.peekChar == '[')
			@s.matchChar('[')
			exprTemp = expression
			@s.matchChar(']')
			t = "["+exprTemp+"]"
		end
		return t
	end

	def identifier
		temp = id
		temp << identifier_tail
		return temp
	end

	def identifier_tail
		temp = ""
		if(@s.peekChar == '[')
			@s.matchChar('[')
			temp = "[" 
			exprTemp = expression
			temp << exprTemp
			@s.matchChar(']')
			temp << "]"
		end
		return temp
	end

	#function to check if the given token is an identifier
	def id
		temp = letter
		temp << let_or_dig("")
		return temp
	end

	def let_or_dig(var)
		if(@alph.has_key?(@s.peekChar))
			var << letter
			temp = var
			return let_or_dig(temp)
		elsif(@dig.has_key?(@s.peekChar))
			var << digit
			temp = var
			return let_or_dig(temp)
		elsif(@s.peekChar == '_')
			var << "_"
			@s.matchChar('_')
			temp = var
			return let_or_dig(temp)
		end
		return var
	end

	#function to check if the current token is a number
	def number
		temp = ""
		temp << digit
		temp << number_tail("")
		return temp
	end

	def number_tail(temp)
		if(@dig.has_key?(@s.peekChar))
			temp << digit
			return number_tail(temp)
		elsif(@alph.has_key?(@s.peekChar))
			raise "Error"
		end
		return temp
	end

	#checks if the current token is a letter, if it is returns true, else false
	def letter
		temp = ""
		if(@alph.has_key?(@s.peekChar))
			temp = @s.peekChar
			@s.NextChar
		else 
			raise "Error"
		end
		return temp
	end


#function to check if the current token's beginning character is a digit
	def digit
		temp = ''
		if(@dig.has_key?(@s.peekChar))
			temp << @s.peekChar
			@s.NextChar
		else 
			raise "Error"
		end
		return temp
	end

	def meta_statement
		if(@s.peekChar == '/')
			@s.matchMetaChar('/')
			@s.matchMetaChar('/')
			meta_statement_tail
			return true
		elsif(@s.peekChar == '#')
			@s.matchMetaChar('#')
			meta_statement_tail
			return true
		else
			puts ""
			return false
		end
	end

	def meta_statement_tail
		if(@s.peekEnd != "\n")
			@s.NextMetaChar
			meta_statement_tail
		end
	end

#checks if the token is a string
	def str
		if(@s.peekChar == '"')
			@s.matchStrChar('"')
			@tempO.push('"')
			while(@s.peekStrChar != '"')
				@tempO.push(@s.nextStrChar)
			end
			@s.matchChar('"')
			@tempO.push('"')
		else
			raise "Error"
		end
	end

	def refreshTable
		@symTable.clear
		@symTable.update(@backupTable)
	end

	def assignment(nam)
		temp = "  " + nam + " = "
		return temp
	end

	def getLocal
		temp = "local[" + @var_counter.to_s + "]"
		@var_counter += 1
		return temp
	end

	def generateLabel
		temp = "L_"
		temp << @label_count.to_s
		@label_count += 1
		return temp
	end

	def getGlobal
		temp = "global[" + @global_var_counter.to_s + "]"
		@global_var_counter += 1
		return temp
	end

	def writeList()

	end


	#the function that is called to start the parser
	def parse(input)
		@s = Scanner.new(input)
		@alph = Hash['a' => nil, 'b' => nil, 'c' => nil, 'd' => nil, 'e' => nil, 'f' => nil, 'g' => nil, 'h' => nil, 'i' => nil, 'j' => nil, 'k' => nil, 'l' => nil, 'm' => nil,  
			'n' => nil, 'o' => nil, 'p' => nil, 'q' => nil, 'r' => nil, 's' => nil, 't' => nil, 'u' => nil, 'v' => nil, 'w' => nil, 'x' => nil, 'y' => nil, 'z' => nil, 
			'A' => nil, 'B' => nil, 'C' => nil, 'D' => nil, 'E' => nil, 'F' => nil, 'G' => nil, 'H' => nil, 'I' => nil, 'J' => nil, 'K' => nil, 'L' => nil, 'M' => nil, 'N' => nil, 
			'O' => nil, 'P' => nil, 'Q' => nil, 'R' => nil, 'S' => nil, 'T' => nil, 'U' => nil, 'V' => nil, 'W' => nil, 'X' => nil, 'Y' => nil, 'Z' => nil]
		@dig = Hash['0' => nil, '1' => nil, '2' => nil, '3' => nil, '4' => nil, '5' => nil, '6' => nil, '7' => nil, '8' => nil, '9' => nil]
		@global_var_counter = 0
		@global_non_empty = false
		@symTable = Hash.new
		@backupTable = Hash.new
		@output = Array.new
		@var_counter = 0
		@func_counter = 0
		@statement_counter = 0
		@continue_label = ""
		@label_count = 0
		@tempO = Array.new
		@is_break = false
		@break_label= ""
		program
	if @s.end?
		puts ""
		for a in @output
			@s.outputCode(a)
		end
    else
        puts "Error"
    end
	end
end

#takes in arguement from command line and calls parser to start the program
arg = ARGV[0]
p = Parser.new
p.parse(arg)

