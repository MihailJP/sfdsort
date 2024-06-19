#!/usr/bin/env ruby

require 'optparse'
prm = {order: 0, defaultFirst: false}
opt = OptionParser.new
opt.banner = "Usage: #{$0} [options] infile"
opt.on('-e', '--encoding-order',     'Reorder glyphs by encoding (default)') {|v| prm[:order] = 0}
opt.on('-u', '--unicode-order',      'Reorder glyphs by (primary) Unicode')  {|v| prm[:order] = 1}
opt.on('-n', '--name-order',         'Reorder glyphs by name')               {|v| prm[:order] = 2}
opt.on('-d', '--default-char-first', 'Reorder .notdef, .null, and nonmarkingreturn before all the others (in this order)') {|v| prm[:defaultFirst] = true}
opt.default_argv = ["--help"]
opt.parse!

def parseSfd(file)
	lines = IO.readlines(file, chomp: true)
	raise "not a spline font database file" if lines[0] !~ /^SplineFontDB:/
	parsed = {header: [], glyphs: {}, order: []}
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
		end

		if currentGlyph.nil? then
		elsif currentGlyph == "" then
			parsed[:header].push l
		else
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
		parsedData[:glyphs][g[:name]].each do |l|
			if l =~ /^Encoding:\s+(\d+)\s+(-1|\d+)\s+(\d+)$/ then
				print "Encoding: #{$1} #{$2} #{glyphReorder[$3.to_i]}\n"
			elsif l =~ /^Refer:\s+(\d+)\s+(-1|\d+)\s+(.+)$/ then
				print "Refer: #{glyphReorder[$1.to_i]} #{parsedData[:order][glyphReorder[$1.to_i]][:unicode]} #{$3}\n"
			else
				print "#{l}\n"
			end
		end
	end
	print "EndChars\n"
end

def reorderSfd(parsedData, prm)
	case prm[:order]
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

	if prm[:defaultFirst] then
		[".notdef", ".null", "nonmarkingreturn"].reverse_each do |v|
			if parsedData[:glyphs].key?(v) then
				i = (parsedData[:order].index {|g| g[:name] == v})
				parsedData[:order].unshift parsedData[:order].delete_at(i)
			end
		end
	end

	return parsedData
end

outputSfd reorderSfd(parseSfd(ARGV[0]), prm)
