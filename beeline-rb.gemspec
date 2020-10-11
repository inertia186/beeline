# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'beeline/version'

Gem::Specification.new do |spec|
  spec.name = 'beeline-rb'
  spec.version = Beeline::VERSION
  spec.authors = ['Anthony Martin']
  spec.email = ['beeline@martin-studio.com']

  spec.summary = %q{Bot Framework for BeeChat}
  spec.description = %q{HIVE centric BeeChat bot Framework.}
  spec.homepage = 'https://github.com/inertia186/beeline-rb'
  spec.license = 'CC0 1.0'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0', '>= 2.0.1'
  spec.add_development_dependency 'rake', '~> 13.0', '>= 13.0.1'
  spec.add_development_dependency 'minitest', '~> 5.14', '= 5.14.2'
  spec.add_development_dependency 'minitest-line', '~> 0.6', '= 0.6.5'
  spec.add_development_dependency 'webmock', '~> 3.9', '= 3.9.1'
  spec.add_development_dependency 'vcr', '~> 6.0', '= 6.0.0'
  spec.add_development_dependency 'simplecov', '~> 0.19', '= 0.19.0'
  spec.add_development_dependency 'yard', '~> 0.9', '= 0.9.25'
  spec.add_development_dependency 'byebug', '~> 11.1', '= 11.1.3'
  spec.add_development_dependency 'pry', '~> 0.13', '= 0.13.1'
  spec.add_development_dependency 'pry-coolline', '~> 0.2', '= 0.2.5'
  spec.add_development_dependency 'awesome_print', '~> 1.8', '= 1.8.0'
  spec.add_development_dependency 'irb', '~> 1.2', '= 1.2.7'
  spec.add_development_dependency 'rb-readline', '~> 0.5', '= 0.5.5'

  spec.add_dependency 'hive-ruby', '~> 1.0', '= 1.0.0'
  spec.add_dependency 'faye-websocket', '~> 0.10'
  spec.add_dependency 'permessage_deflate', '~> 0.1', '= 0.1.4'
end
