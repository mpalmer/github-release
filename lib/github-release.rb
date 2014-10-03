require 'octokit'
require 'io/console'

class GithubRelease
	def run
		new_releases = tagged_releases.select { |r| !github_releases.include?(r) }

		if new_releases.empty?
			puts "No new release tags to push."
		end

		new_releases.each { |t| create_release(t) }

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

		api = Octokit::Client.new(:login => user, :password => pass)
		begin
			res = api.create_authorization(:scopes => [:repo], :note => "git release")
		rescue Octokit::Unauthorized
			puts "Username or password incorrect.  Please try again."
			return get_new_token
		end

		token = res[:token]

		system("git config --global release.api-token '#{token}'")

		log_val(token)
	end

	def tag_regex
		@tag_regex ||= `git config --get release.tag-regex`.strip
		@tag_regex = /^v\d+\.\d+(\.\d+)?$/ if @tag_regex.empty?
		log_val(@tag_regex)
	end

	def tagged_releases
		@tagged_releases ||= `git tag`.split("\n").map(&:strip).grep tag_regex
		log_val(@tagged_releases)
	end

	def repo_name
		@repo_name ||= begin
			case repo_url
				when %r{^https://github.com/([^/]+/[^/]+)}
					$1.gsub(/\.git$/, '')
				when %r{^(?:git@)?github\.com:([^/]+/[^/]+)}
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

	def create_release(tag)
		print "Creating a release for #{tag}..."
		system("git push #{remote_name} tag #{tag} >/dev/null 2>&1")

		msg = `git tag -l -n1000 '#{tag}'`

		# Ye ghods is is a horrific format to parse
		name, body = msg.split("\n", 2)
		name = name.gsub(/^#{tag}/, '').strip
		body = body.split("\n").map { |l| l.sub(/^    /, '') }.join("\n")

		api.create_release(repo_name, tag, :name => name, :body => body)

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
