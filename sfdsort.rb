#!/usr/bin/env ruby

require 'optparse'
$prm = {
	order: nil,
	defaultFirst: false,
	glyphOrderFile: nil,
	dropWinInfo: false,
	dropFlagH: false,
	dropFlagO: false,
	deselectAll: false,
	nestedRefs: false,
}
opt = OptionParser.new
opt.banner = "Usage: #{$0} [options] infile"
opt.on('-e', '--encoding-order',     'Reorder glyphs by encoding')          {|v| $prm[:order] = 0}
opt.on('-u', '--unicode-order',      'Reorder glyphs by (primary) Unicode') {|v| $prm[:order] = 1}
opt.on('-n', '--name-order',         'Reorder glyphs by name')              {|v| $prm[:order] = 2}
opt.on('-f', '--custom-order=FILENAME', 'Specify glyph order by file')      {|v| $prm[:glyphOrderFile] = v.to_s}
opt.on('-d', '--default-char-first', 'Reorder .notdef, .null, CR (or nonmarkingreturn), and space before all the others (in this order)') {|v| $prm[:defaultFirst] = true}
opt.on('-w', '--drop-wininfo', 'Drop WinInfo') {|v| $prm[:dropWinInfo] = true}
opt.on('-H', '--drop-hint-flag', 'Drop Flag H from all glyphs') {|v| $prm[:dropFlagH] = true}
opt.on('-O', '--drop-open-flag', 'Drop Flag O from all glyphs') {|v| $prm[:dropFlagO] = true}
opt.on('-D', '--deselect-all', 'Deselect all points and references in all glyphs') {|v| $prm[:deselectAll] = true}
opt.on('-R', '--decompose-nested-references', 'Decompose nested references into single-level ones') {|v| $prm[:nestedRefs] = true}
opt.parse!

def parseSfd(file)
	lines = IO.readlines(file, chomp: true)
	raise "not a spline font database file" if lines[0] !~ /^SplineFontDB:/
	parsed = {header: [], glyphs: {}, order: [], encodingIsOriginal: false}
	currentGlyph = ""
	codeData = {}
	lines.each do |l|
		if l.empty? then
			next
		elsif l =~ /^StartChar:/ then
			currentGlyph = l.sub(/^StartChar:\s*/, "")
			parsed[:glyphs][currentGlyph] = []
			codeData = {name: currentGlyph}
		elsif l =~ /^Encoding:\s+(\d+)\s+(-1|\d+)\s+(\d+)$/ then
			codeData.merge!({encoding: $1.to_i, unicode: $2.to_i, glyphOrder: $3.to_i})
		elsif l =~ /^Encoding:\s+Original\s*$/ then
			parsed[:encodingIsOriginal] = true
		end

		if currentGlyph.nil? then
		elsif currentGlyph == "" then
			parsed[:header].push l unless ($prm[:dropWinInfo] and (l =~ /^WinInfo:/))
		else
			if l =~ /^Flags:/ then
				l.sub!(/H/, "") if $prm[:dropFlagH] = true
				l.sub!(/O/, "") if $prm[:dropFlagO] = true
			end
			parsed[:glyphs][currentGlyph].push l
		end

		if l == "EndChar" then
			currentGlyph = nil
			parsed[:order].push codeData
		end
	end
	return parsed
end

def outputSfd(parsedData)
	glyphReorder = []
	parsedData[:order].each_with_index do |g, i|
		glyphReorder[g[:glyphOrder]] = i
	end
	parsedData[:header].each do |l|
		print "#{l}\n"
	end
	parsedData[:order].each do |g|
		print "\n"
		inSplineSet = false
		parsedData[:glyphs][g[:name]].each do |l|
			if l =~ /^Encoding:\s+(\d+)\s+(-1|\d+)\s+(\d+)$/ then
				print "Encoding: #{parsedData[:encodingIsOriginal] ? glyphReorder[$3.to_i] : $1} #{$2} #{glyphReorder[$3.to_i]}\n"
			elsif l =~ /^Refer:\s+(\d+)\s+(-1|\d+)\s+(\S+)\s+(.+)$/ then
				print "Refer: #{glyphReorder[$1.to_i]} #{parsedData[:order][glyphReorder[$1.to_i]][:unicode]} #{$prm[:deselectAll] && $3 == "S" ? "N" : $3} #{$4}\n"
			elsif $prm[:deselectAll] and inSplineSet and (l =~ /^(.*)\s+(\d+)$/) then
				print "#{$1} #{$2.to_i & (~4)}\n"
			else
				inSplineSet = true if l == "SplineSet"
				inSplineSet = false if l == "EndSplineSet"
				print "#{l}\n"
			end
		end
	end
	print "EndChars\n"
	print "EndSplineFont\n"
end

def moveGlyphToTop(parsedData, glyphName)
	if parsedData[:glyphs].key?(glyphName) then
		i = (parsedData[:order].index {|g| g[:name] == glyphName})
		parsedData[:order].unshift parsedData[:order].delete_at(i)
		return glyphName
	else
		return nil
	end
end

def toval(strval)
	return strval.to_i == strval.to_f ? strval.to_i : strval.to_f
end

def matprod(mat1, mat2)
	#
	# a1 a2 0   b1 b2 0     a1b1+a2b3    a1b2+a2b4    0
	# a3 a4 0   b3 b4 0  =  a3b1+a4b3    a3b2+a4b4    0
	# a5 a6 1   b5 b6 1     a5b1+a6b3+b5 a5b2+a6b4+b6 1
	#
	return [
		mat1[0] * mat2[0] + mat1[1] * mat2[2],
		mat1[0] * mat2[1] + mat1[1] * mat2[3],
		mat1[2] * mat2[0] + mat1[3] * mat2[2],
		mat1[2] * mat2[1] + mat1[3] * mat2[3],
		mat1[4] * mat2[0] + mat1[5] * mat2[2] + mat2[4],
		mat1[4] * mat2[1] + mat1[5] * mat2[3] + mat2[5],
	]
end

def affinetransform(x, y, mat)
	#
	#         m1 m2 0
	# x y 1   m3 m4 0  =  m1x+m3y+m5 m2x+m4y+m6 1
	#         m5 m6 1
	#
	return [mat[0] * x + mat[2] * y + mat[4], mat[1] * x + mat[3] * y + mat[5]]
end

def transformContours(contours, matrix)
	newContours = []
	contours.each do |l|
		if l =~ /^(\s*)(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(\D.*)$/ then # line or beginning
			newCoord = affinetransform(toval($2), toval($3), matrix)
			newContours.push "#{$1}#{newCoord[0]} #{newCoord[1]} #{$4}"
		elsif l =~ /^(\s*)(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(\D.*)$/ then # quadratic
			newCoord1 = affinetransform(toval($2), toval($3), matrix)
			newCoord2 = affinetransform(toval($4), toval($5), matrix)
			newContours.push "#{$1}#{newCoord1[0]} #{newCoord1[1]} #{newCoord2[0]} #{newCoord2[1]} #{$6}"
		elsif l =~ /^(\s*)(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(\D.*)$/ then # cubic
			newCoord1 = affinetransform(toval($2), toval($3), matrix)
			newCoord2 = affinetransform(toval($4), toval($5), matrix)
			newCoord3 = affinetransform(toval($6), toval($7), matrix)
			newContours.push "#{$1}#{newCoord1[0]} #{newCoord1[1]} #{newCoord2[0]} #{newCoord2[1]} #{newCoord3[0]} #{newCoord3[1]} #{$8}"
		else # malformed
			warn "Malformed spline definition: #{l}"
			newContours.push l
		end
	end
	return newContours
end

def decomposeNestedGlyphs(parsedData)
	if $prm[:nestedRefs] then
		# Parse references
		refs = {}
		parsedData[:order].each do |g|
			glyphOrder = nil
			splines = []
			layers = 2
			currentLayer = 0
			inSplineDefinition = false
			parsedData[:glyphs][g[:name]].each do |l|
				if l =~ /^Encoding:\s+(\d+)\s+(-1|\d+)\s+(\d+)$/ then
					glyphOrder = $3.to_i
				elsif l =~ /^LayerCount: (\d+)$/ then
					layers = $1.to_i
					splines = Array.new(layers) {[]}
				elsif l =~ /^Back$/ then
					currentLayer = 0
					inSplineDefinition = false
				elsif l =~ /^Fore$/ then
					currentLayer = 1
					inSplineDefinition = false
				elsif l =~ /^Layer: (\d+)$/ then
					currentLayer = $1.to_i
					inSplineDefinition = false
				elsif l =~ /^SplineSet$/ then
					inSplineDefinition = true
				elsif l =~ /^EndSplineSet$/ then
					inSplineDefinition = false
				elsif l =~ /^Refer:\s+(\d+)\s+(-1|\d+)\s+(\S+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(-?\d*\.?\d+)\s+(.+)$/ then
					inSplineDefinition = false
					if not refs.key?(glyphOrder) then
						refs[glyphOrder] = {splines: splines, refs: []}
					end
					refs[glyphOrder][:refs].push({
						glyphId: $1.to_i, unicode: $2.to_i,
						matrix: [toval($4), toval($5), toval($6), toval($7), toval($8), toval($9)],
						flags: $10
					})
				elsif inSplineDefinition then
					splines[currentLayer].push l
				end
			end
		end

		# Dereference
		nestFound = false
		begin
			nestFound = false
			refs.each do |glyphId, r|
				newref = []
				r[:refs].each do |rr|
					if refs.key?(rr[:glyphId]) then
						refs[rr[:glyphId]][:refs].each do |subref|
							newref.push({
								glyphId: subref[:glyphId], unicode: subref[:unicode],
								matrix: matprod(subref[:matrix], rr[:matrix]),
								flags: subref[:flags]
							})
							if refs.key?(subref[:glyphId])
								numOfLayers1 = r[:splines].length
								numOfLayers2 = refs[rr[:glyphId]][:splines].length
								warn "Number of layers mismatch: #{numOfLayers1} for glyph #{glyphId} and #{numOfLayers2} for glyph #{subref[:glyphId]}" if numOfLayers1 != numOfLayers2
								for layer in 0...([numOfLayers1, numOfLayers2].min) # unlikely mismatch
									r[:splines][layer] += transformContours(refs[rr[:glyphId]][:splines][layer], rr[:matrix])
								end
							end
						end
						nestFound = true
					else
						newref.push rr
					end
				end
				r[:refs] = newref
			end
		end while nestFound

		# Clear layers
		refs.each do |glyphId, r|
			layers = 2
			currentLayer = 0
			inSplineDefinition = false
			currentGlyph = parsedData[:glyphs][parsedData[:order][glyphId][:name]]
			for i in 0...(currentGlyph.length)
				l = currentGlyph[i]
				if l =~ /^LayerCount: (\d+)$/ then
					layers = $1.to_i
				elsif l =~ /^Back$/ then
					currentLayer = 0
					inSplineDefinition = false
					currentGlyph[i] = ""
				elsif l =~ /^Fore$/ then
					currentLayer = 1
					inSplineDefinition = false
					currentGlyph[i] = ""
				elsif l =~ /^Layer: (\d+)$/ then
					currentLayer = $1.to_i
					inSplineDefinition = false
					currentGlyph[i] = ""
				elsif l =~ /^SplineSet$/ then
					inSplineDefinition = true
					currentGlyph[i] = ""
				elsif l =~ /^EndSplineSet$/ then
					inSplineDefinition = false
					currentGlyph[i] = ""
				elsif inSplineDefinition then
					currentGlyph[i] = ""
				end
			end
		end

		# Update glyphs
		parsedData[:order].each do |g|
			newGlyph = []
			glyphOrder = nil
			layers = 2
			parsedData[:glyphs][g[:name]].each do |l|
				if l == "" then
					# skip
				elsif l =~ /^Encoding:\s+(\d+)\s+(-1|\d+)\s+(\d+)$/ then
					glyphOrder = $3.to_i
					newGlyph.push l
				elsif l =~ /^LayerCount: (\d+)$/ then
					layers = $1.to_i
					newGlyph.push l
					if refs.key?(glyphOrder) then
						for layer in 0...layers
							unless refs[glyphOrder][:splines][layer].empty?
								newGlyph.push layer == 0 ? "Back" : layer == 1 ? "Fore" : "Layer: #{layer}"
								newGlyph.push "SplineSet"
								newGlyph += refs[glyphOrder][:splines][layer]
								newGlyph.push "EndSplineSet"
							end
						end
					end
					#newGlyph.push "Back"
					#newGlyph.push "Fore"
				elsif l =~ /^Refer:\s+(\d+)\s+(-1|\d+)\s+(\S+)\s+(.+)$/ then
					newGlyph.push l unless refs.key?(glyphOrder)
				elsif l =~ /^EndChar$/ then
					if refs.key?(glyphOrder) then
						refs[glyphOrder][:refs].each do |r|
							newGlyph.push "Refer: #{r[:glyphId]} #{r[:unicode]} N #{r[:matrix][0]} #{r[:matrix][1]} #{r[:matrix][2]} #{r[:matrix][3]} #{r[:matrix][4]} #{r[:matrix][5]} #{r[:flags]}"
						end
					end
					newGlyph.push l
				else
					newGlyph.push l
				end
			end
			parsedData[:glyphs][g[:name]] = newGlyph
		end
	end
	return parsedData
end

def reorderSfd(parsedData)
	case $prm[:order]
	when 0
		parsedData[:order].sort_by! {|v| v[:encoding]}
	when 1
		parsedData[:order].sort! {|a, b|
			if a[:unicode] == -1 and b[:unicode] == -1 then
				a[:glyphOrder] <=> b[:glyphOrder]
			elsif a[:unicode] == -1 then
				1
			elsif b[:unicode] == -1 then
				-1
			else
				a[:unicode] <=> b[:unicode]
			end
		}
	when 2
		parsedData[:order].sort_by! {|v| v[:name]}
	end

	unless $prm[:glyphOrderFile].nil? then
		IO.readlines($prm[:glyphOrderFile], chomp: true).reverse_each {|v|
			unless moveGlyphToTop(parsedData, v) then
				warn "Glyph \"#{v}\" not found"
			end
		}
	end

	if $prm[:defaultFirst] then
		[".notdef", ".null", "CR", "nonmarkingreturn", "space"].reverse_each {|v| moveGlyphToTop(parsedData, v)}
	end

	return parsedData
end

outputSfd reorderSfd(decomposeNestedGlyphs(parseSfd(ARGV[0])))
