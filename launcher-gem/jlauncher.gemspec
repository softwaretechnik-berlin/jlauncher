lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jlauncher/version"

Gem::Specification.new do |spec|
  spec.name          = "jlauncher"
  spec.version       = JLauncher::VERSION
  spec.authors       = ["Felix Leipold"]
  spec.email         = ["felix.leipold@gmail.com"]

  spec.summary       = %q{Launches jvm software from central repos}
  spec.description   = %q{Uses fully resolved dependencies to get and start software from central repos}
  spec.homepage      = "https://github.com/softwaretechnik-berlin/jlauncher"
  spec.license       = "MIT"

  
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_dependency('optimist')
  spec.add_dependency('colorize')
  spec.add_dependency('rubyzip')
  spec.add_dependency('httparty')
end
