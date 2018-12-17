class Scanner

	#initilizing the Scanner with its variables
	def initialize(file_name)
		@input_file = File.open(file_name)
		@allLines = @input_file.readlines
		@output_file = File.new("outputfile.c", "w")
		@Line = @allLines[0]
		@allLines.shift
	end

	#moves to the next line and detects white space to output an empty line and moves onto the next line
	def nextLine
		while (@allLines[0] == "" || @allLines[0] == "\r\n" || @allLines[0] == "\n")
			@allLines.shift
		end
		if(@allLines[0]!=nil)
			@Line = @allLines[0]
			@allLines.shift
			checkSpace
		end
	end

	def peekEnd
		return @Line
	end

	def peek
		checkLine
		checkSpace
		return @Line
	end

	def checkSpace
		if(@Line[0] == nil)
		elsif(@Line[0] == " " || @Line[0] == "\t")
			while(@Line[0] == " " || @Line[0] == "\t")
				@Line.slice!(0,1)
			end
		else
		end
	end

	def newLine
		@output_file.puts ""
	end

	def nextStrChar
		temp = @Line[0]
		@Line.slice!(0, 1)
		return temp
	end

	def matchStrChar(c)
		raise "rejects wrong match" unless c == @Line[0]
			@Line.slice!(0,1)
	end

#prints first character of cur_tok and then deletes the character
	def NextChar
		@Line.slice!(0, 1)
	end

	def matchMetaChar(c)
		raise "rejects wrong match" unless c == @Line[0]
			@output_file.print(c)
			print c
			@Line.slice!(0, 1)
	end

	def outputCode(s)
		@output_file.print s
		print s
	end

	def NextMetaChar
		@output_file.print @Line[0]
		print @Line[0]
		@Line.slice!(0, 1)
	end

#method used to put iterate through a string in the language
	def stringNextChar
		@Line.slice!(0, 1)
		checkLine
	end

	def peekStrChar
		return @Line[0]
	end

#changes the name of an identifier, a function or variable
	def changeName
		checkSpace
	end 

#same as match but just with the first characater of cur_tok
	def matchChar(c)
		checkSpace
		checkLine
		raise "rejects wrong match" unless c == @Line[0]
			@Line.slice!(0, 1)
			#@output_file.print c
			checkSpace
	end 

#returns the first character of cur_tok string
	def peekChar
		checkLine
		checkSpace
		return @Line[0]
	end

	def peekCh_include_space
		checkLine
		return @Line[0]
	end

#checks if the Line array is empty and needs to be filled
	def checkLine
		if(@Line == "" || @Line == nil || @Line == "\n" || @Line == "\r\n")
			nextLine
		end
	end

	#returns the line array of strings
	def getLine
		return @Line
	end

	def match(tok)
		chars = tok.split("")
		chars.each { |ch|
			matchChar(ch)
		}
		checkSpace
		checkLine
	end

	#checks if the file has been completely run through
	def end?
		if(@allLines.empty?)
			return true
		else
			return false
		end
	end
end
