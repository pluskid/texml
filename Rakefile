task :default => [:gem]

task :gem => [:treetop] do
  sh 'gem build texml.gemspec'
end

task :treetop do
  sh 'tt lib/texml/texml.treetop'
end

