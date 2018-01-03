require 'git-version-bump'

Gem::Specification.new do |s|
	s.name = "github-release"

	s.version = GVB.version
	s.date    = GVB.date

	s.platform = Gem::Platform::RUBY

	s.homepage = "http://theshed.hezmatt.org/github-release"
	s.summary = "Upload tag annotations to github"
	s.authors = ["Matt Palmer"]

	s.extra_rdoc_files = ["README.md"]
	s.files = `git ls-files`.split("\n")
	s.executables = ["git-release"]

	s.add_dependency 'octokit', '>= 3.0', '< 5'
	s.add_dependency 'git-version-bump'

	s.add_development_dependency 'rake'
	s.add_development_dependency 'bundler'
	s.add_development_dependency 'rdoc'
end
