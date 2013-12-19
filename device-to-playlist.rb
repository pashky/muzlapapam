#!/usr/bin/ruby
require 'rubygems'
require 'appscript'
require 'fileutils'
require 'set'


unless ARGV.size == 2
  puts "device-to-playlist.rb [device] [playlist]"
  exit
end

device, playlist_name = ARGV

#### no config beyond this point

itu = Appscript.app("iTunes.app")
whose = Appscript.its

device = itu.sources.get.select { |s|
  s.name.get.downcase.gsub(/[^a-z]/, '') == device.downcase.gsub(/[^a-z]/, '')
}.first

library = itu.sources[whose.kind.eq(:library)][1]

lib_playlist = library.playlists[whose.name.eq(playlist_name)][1]
unless lib_playlist.exists 
  lib_playlist = itu.make(:new => :user_playlist, :with_properties => {:name => playlist_name})
else
  itu.delete(lib_playlist.tracks)
end

dev_playlist = device.library_playlists[1]
dev_playlist.tracks.get.each do |track|
  id = track.persistent_ID.get
  artist = track.artist.get
  album = track.album.get
  name = track.name.get
  
  lib_track = library.tracks[whose.persistent_ID.eq(id)]
  lib_track = library.tracks[whose.name.eq(name).and(whose.artist.eq(artist)).and(whose.album.eq(album))] unless lib_track.exists
  lib_track = library.tracks[whose.name.eq(name).and(whose.artist.eq(artist))] unless lib_track.exists

  if lib_track.exists
    itu.duplicate(lib_track[1], :to => lib_playlist)
  else
    puts "Not found: #{id} ----- #{artist} | #{album} | #{name}"
  end
  
end

puts "Complete"
