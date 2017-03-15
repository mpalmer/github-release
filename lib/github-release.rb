require 'octokit'
require 'io/console'

class GithubRelease
	def run
		new_prereleases = tagged_prereleases.select { |p| !github_releases.include?(p) }

		if new_prereleases.empty?
			puts "No new pre-release tags to push."
		end

		new_prereleases.each { |t| create_release(t, true) }

		new_releases = tagged_releases.select { |r| !github_releases.include?(r) }

		if new_releases.empty?
			puts "No new release tags to push."
		end

		new_releases.each { |t| create_release(t, false) }

		puts "All done!"
	end

	private
	def api
		@api ||= Octokit::Client.new(:access_token => token, :auto_paginate => true)
	end

	def token
		@token ||= begin
			# We cannot use the 'defaults' functionality of git_config here,
			# because get_new_token would be evaluated before git_config ran
			git_config("release.api-token") || get_new_token
		end

		log_val(@token)
	end

	def get_new_token
		puts "Requesting a new OAuth token from Github..."
		print "Github username: "
		user = $stdin.gets.chomp
		print "Github password: "
		pass = $stdin.noecho(&:gets).chomp
		puts

		headers = {}

		api = Octokit::Client.new(:login => user, :password => pass)
		begin
			res = api.create_authorization(:scopes => [:repo], :note => "git release #{Time.now.strftime("%FT%TZ")}", :headers => headers)
		rescue Octokit::OneTimePasswordRequired
			print "OTP code: "
			headers["X-GitHub-OTP"] = $stdin.gets.chomp
			retry
		rescue Octokit::Unauthorized
			puts "Credentials incorrect.  Please try again."
			return get_new_token
		end

		token = res[:token]

		system("git config --global release.api-token '#{token}'")

		log_val(token)
	end

	def pre_regex
		config_entry = `git config --get release.pre-regex`.strip
		@pre_regex = /#{config_entry}/ if !config_entry.empty?
		@pre_regex ||= /^v\d+\.\d+(\.\d+)?(-rc\d+.*){1}$/
		log_val(@pre_regex)
	end

	def tag_regex
		config_entry = `git config --get release.tag-regex`.strip
		@tag_regex = /#{config_entry}/ if !config_entry.empty?
		@tag_regex ||= /^v\d+\.\d+(\.\d+)?$/
		log_val(@tag_regex)
	end

	def tagged_releases
		@tagged_releases ||= `git tag`.split("\n").map(&:strip).grep tag_regex
		log_val(@tagged_releases)
	end

	def tagged_prereleases
		@tagged_prereleases ||= `git tag`.split("\n").map(&:strip).grep pre_regex
		log_val(@tagged_prereleases)
	end

	def repo_name
		@repo_name ||= begin
			case repo_url
				when %r{^https://github.com/([^/]+/[^/]+)}
					$1.gsub(/\.git$/, '')
				when %r{^(?:git@)?github\.com:/?([^/]+/[^/]+)}
					$1.gsub(/\.git$/, '')
				else
					raise RuntimeError,
					      "I cannot recognise the format of the push URL for remote #{remote_name} (#{repo_url})"
			end
		end
		log_val(@repo_name)
	end

	def repo_url
		@repo_url ||= begin
			git_config("remote.#{remote_name}.pushurl") || git_config("remote.#{remote_name}.url")
		end
		log_val(@repo_url)
	end

	def remote_mirror
		@remote_mirror ||= git_config("remote.#{remote_name}.mirror")
		log_val(@remote_mirror)
	end

	def remote_name
		@remote_name ||= git_config("release.remote", "origin")
		log_val(@remote_name)
	end

	def github_releases
		@github_releases ||= api.releases(repo_name).map(&:tag_name)
		log_val(@github_releases)
	end

	def git_config(item, default = nil)
		@config_cache ||= {}

		@config_cache[item] ||= begin
			v = `git config #{item}`.strip
			v.empty? ? default : v
		end

		log_val(@config_cache[item], item)
	end

	def create_release(tag, prerelease)
		@pushed ||= false
		if remote_mirror == "true" && @pushed == false
			puts "Pushing to #{remote_name}..."
			system("git push #{remote_name}")
			@pushed = true
		elsif remote_mirror != "true"
			puts "Pushing #{tag} to #{remote_name}..."
			system("git push #{remote_name} tag #{tag}")
		end

		print "Creating a release for #{tag}..."
		msg = `git tag -l -n1000 '#{tag}'`

		# Ye ghods is is a horrific format to parse
		name, body = msg.split("\n", 2)
		name = name.gsub(/^#{tag}/, '').strip
		body = body.split("\n").map { |l| l.sub(/^    /, '') }.join("\n")

		api.create_release(repo_name, tag, :name => name, :body => body, :prerelease => prerelease)

		puts " done!"
	end

	def log_val(v, note = nil)
		return v unless $DEBUG

		calling_func = caller[0].split("`")[-1].sub(/'$/, '')

		print "#{note}: " if note
		puts "#{calling_func} => #{v.inspect}"

		v
	end
end
