#!/usr/bin/ruby
require 'rubygems'
require 'appscript'
require 'fileutils'
require 'RMagick'
require 'set'
include Magick

export_dir = '/Volumes/SANSA64/Library'
#playlist_dir = '/Volumes/SANSACLIPZ/Playlists'
playlist_dir = '/Volumes/SANSA64/Playlists'
playlist_prefix = '/<microSD1>/Library'

unless ARGV.size > 0
  puts "sync.rb [playlist name] [playlist name]..."
  exit
end

playlists = ARGV

#### no config beyond this point

processed_tracks = Set.new
processed_artworks = Set.new

itu = Appscript.app("iTunes.app")
whose = Appscript.its
library = itu.sources[whose.kind.eq(:library)][1]

def safename(t)
  t.gsub(/[\/\\]/, '_'); 
end

playlists.each do |playlist_name|
  puts "Processing playlist #{playlist_name}"
  
  playlist = library.user_playlists[whose.name.eq(playlist_name)][1]

  tracks = playlist.tracks.get
  total_tracks = tracks.size

  playlist_files = []
  tracks.each_with_index do |track, i_track|
    id = track.database_ID.get
    
    album_artist = track.album_artist.get
    album_artist = track.artist.get if album_artist.empty?
    album = track.album.get
    year = track.year.get
    album = 'Unknown' if album.empty?
    album = "#{year} #{album}" if year > 0
    name = track.name.get
    num = track.track_number.get
    name = "#{num} #{name}" if num > 0

    location = track.location.get.path
    extension = File.extname(location)

    relative_filepath = File.join([album_artist, album, name + extension].map{|x| safename(x)})
    playlist_files.push(relative_filepath)
    
    filepath = File.join(export_dir, relative_filepath)
    albumpath = File.dirname(filepath)

    percent = i_track * 100 / total_tracks;
    puts "[#{percent}%] #{filepath}"

    next if processed_tracks.include?(id)
    processed_tracks.add(id)
    
    unless processed_artworks.include?(albumpath) then
      processed_artworks.add(albumpath)
      
      FileUtils.mkpath(albumpath)
      artworkpath = File.join(albumpath, 'cover.jpg')
      if !File.exists?(artworkpath) then
        begin 
          image = Image.from_blob(track.artworks[1].data_.get.data).first
          image.change_geometry('300x300') { |cols, rows, img| img.resize!(cols, rows) }
          image.write(artworkpath)
        rescue
          # say something?
        end
      end
    end


    if !File.exists?(filepath) || File.size(filepath) != File.size(location) then
      FileUtils.cp location, filepath
    end

  end

  playlistpath = File.join(playlist_dir, safename(playlist_name) + ".m3u8")
  FileUtils.mkpath(playlist_dir)
  File.open(playlistpath, "w") { |f| f.puts playlist_files.map{|n| File.join(playlist_prefix, n)} }
end

puts "Complete"
