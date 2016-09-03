Gem::Specification.new do |s|
  s.name        = 'gippix'
  s.version     = '0.0.2'
  s.date        =  DateTime.now.strftime "%Y-%m-%d"
  s.summary     = "GPX parser/ reader"
  s.description = "Reads GPX files."
  s.authors     = ["Andrew Libby"]
  s.email       = 'alibby@andylibby.org'
  s.files       = ["lib/gippix.rb"]
  s.homepage    = 'http://rubygems.org/xforty/gippix'
  s.license     = 'MIT'
  s.add_runtime_dependency 'nokogiri', '~> 1.1', '>= 1.1.4'

end
