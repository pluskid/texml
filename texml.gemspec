Gem::Specification.new do |s|
  s.name = 'texml'
  s.version = '0.0.0'
  s.date = '2012-06-13'
  s.summary = 'TeX Markup Language'
  s.description = 'A markup which generate TeX and HTML output'
  s.authors = ['pluskid']
  s.email = 'pluskid@gmail.com'
  s.files = Dir['lib/**/*']
  s.homepage = 'https://github.com/pluskid/texml'

  s.add_runtime_dependency 'treetop', '~> 1.4', '>= 1.4.10'
end
