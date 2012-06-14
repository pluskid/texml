# -*- coding: utf-8 -*-
require 'pp'
require 'polyglot'
require 'treetop'

require 'texml'

parser = TeXMLParser.new
text = File.read('test.txt')

result = parser.parse(text)

if !result
  puts parser.failure_reason
  exit
end

pp result.value

doc = TeXMLLaTeXDoc.new
puts doc.render_node(result.value).flatten.join
