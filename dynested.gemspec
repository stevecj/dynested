# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "dynested"
  s.description = "Dynamic, browser-side nested attribute support for Rails."
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "0.1.6"
  s.summary = "Dynested %s" % s.version 
end
