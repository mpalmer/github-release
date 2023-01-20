This very simple gem provides a `git release` command, which will
automatically fill out any and all "release tags" into fully-blown "Github
Releases", complete with release notes, a heading, and all the other good
things in life.

Using this gem, you can turn the following tag annotation:

    First Release

    It is with much fanfare and blowing of horns that I bequeath the
    awesomeness of `git release` upon the world.

    Features in this release include:

     * Ability to create a release from a tag annotation or commit message;
     * Automatically generates an OAuth token if needed;
     * Feeds your cat while you're hacking(*)

    You should install it now!  `gem install github-release`

Into [this](https://github.com/mpalmer/github-release/releases/tag/v0.1.0)
simply by running

    git release


# Installation

Simply install the gem:

    gem install github-release


# Usage

Using `git release` is very simple.  Just make sure that your `origin`
remote points to your Github repo, and then run `git release`.  All tags
that look like a "version tag" (see "Configuration", below) will be created
as Github releases (if they don't already exist) and the message from the
tag will be used as the release notes.

The format of the release notes is quite straightforward -- the first line
of the message associated with the commit will be used as the "name" of the
release, with the rest of the message used as the "body" of the release.
The body will be interpreted as Github-flavoured markdown, so if you'd like
to get fancy, go for your life.

The message associated with the "release tag" is either the tag's annotation
message (if it is an annotated tag) or else the commit log of the commit on
which the tag is placed.  I *strongly* recommend annotated tags (but then
again, [I'm biased...](http://theshed.hezmatt.org/git-version-bump))

The first time you use `git release`, it will ask you for your Github
username and password.  This is used to request an OAuth token to talk to
the Github API, which is then stored in your global git config.  Hence you
*shouldn't* be asked for your credentials every time you use `git release`.
If you need to use multiple github accounts for different repos, you can
override the `release.api-token` config parameter in your repo configuration
(but you'll have to get your own OAuth token).


# Configuration

There are a few things you can configure to make `git release` work slightly
differently.  None of them should be required for normal, sane use.

 * `release.remote` (default `origin`) -- The name of the remote which is
   used to determine what github repository to send release notes to.

 * `release.api-token` (default is runtime generated) -- The OAuth token
   to use to authenticate access to the Github API.  When you first run `git
   release`, you'll be prompted for a username and password to use to
   generate an initial token; if you need to override it on a per-repo
   basis, this is the key you'll use.

 * `release.tag-regex` (default `v\d+\.\d+(\.\d+)?$`) -- The regular
   expression to filter which tags denote releases, as opposed to other tags
   you might have decided to make.  Only tags which match this regular
   expression will be pushed up by `git release`, and only those tags will
   be marked as releases.

 * `release.pre-regex` (default `v\d+\.\d+(\.\d+)?(-(alpha|beta|rc)\d+.*){1}$`)
   -- The regular expression to filter which tages denote prereleases.
   Only tags which match this regular expression will be pushed up by
   `git release`, and these will be marked as Pre-release on the github
   release pages.


# License

Unless otherwise stated, everything in this repo is covered by the following
copyright notice:

    Copyright (C) 2014  Matt Palmer <matt@hezmatt.org>

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
