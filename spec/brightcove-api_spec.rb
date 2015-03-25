require 'spec_helper'
require 'open-uri'

describe Brightcove::API do
  it 'should be the correct version' do
    expect(Brightcove::API::VERSION).to eq('1.0.18')
  end

  it 'should allow you to set new HTTP headers' do
    brightcove = Brightcove::API.new('apikeytoken')
    Brightcove::API.expects(:headers).at_least_once

    brightcove.set_http_headers({'Accept' => 'application/json'})
  end

  it 'should allow you to set a new default timeout' do
    brightcove = Brightcove::API.new('apikeytoken')
    Brightcove::API.expects(:default_timeout).at_least_once

    brightcove.set_timeout(5)
  end

  it 'should allow you to find all videos' do
    VCR.use_cassette('find_all_videos') do
      brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
      brightcove_response = brightcove.get('find_all_videos', {:page_size => 5})

      expect(brightcove_response['items'].size).to eq(5)
      expect(brightcove_response['page_number']).to eq(0)
    end
  end

  it 'should allow you to find all videos using MRSS output' do
    VCR.use_cassette('find_all_videos_mrss') do
      brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
      brightcove_response = brightcove.get('find_all_videos', {:output => 'mrss'})

      expect(brightcove_response['rss']['channel']['item'].size).to eq(85)
    end
  end

  it 'should allow you to search with array parameters' do
    brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
    brightcove.class.expects(:get).with(anything, has_entry(:query => {
      :any => ['tag:foo', 'tag:bar'],
      :command => 'search_videos',
      :token => '0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.'
    }))

    brightcove_response = brightcove.get('search_videos', { :any => [ "tag:foo", "tag:bar" ] })
  end

  it 'should allow you to search with string parameters' do
    brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
    brightcove.class.expects(:get).with(anything, has_entry(:query => {
      'any' => ['tag:bar', 'tag:foo'],
      :command => 'search_videos',
      :token => '0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.'
    }))

    brightcove_response = brightcove.get('search_videos', 'any=tag:bar&any=tag:foo' )
  end

  it 'should allow you to create a more complicated search query' do
    brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
    brightcove.class.expects(:get).with(anything, has_entry(:query => {
      :any => ['tag:foo', 'tag:bar'],
      :all => "search_text:foo",
      :command => 'search_videos',
      :token => '0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.'
    }))

    brightcove_response = brightcove.get('search_videos', { :any => [ "tag:foo", "tag:bar" ], :all => "search_text:foo" })
  end

  it 'should allow you to construct a query from the Brightcove Media API examples' do
    VCR.use_cassette('brightcove_media_api_example_query') do
      brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
      brightcove_response = brightcove.get('search_videos', {
        :any => [ "tag:color", "tag:technicolor" ],
        :all => ["football", "chicago", "tag:free"]
      })

      expect(brightcove_response['items'].size).to eq(0)
    end
  end

  it 'should allow you to delete a video' do
    VCR.use_cassette('delete_video', :serialize_with => :yaml) do
      brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
      brightcove_response = brightcove.post('delete_video', {:video_id => '595153261337'})

      expect(brightcove_response).to have_key('result')
      expect(brightcove_response['error']).to be_nil
    end
  end

  it 'should allow you to create a video using #post_file' do
    VCR.use_cassette('post_file', :serialize_with => :yaml) do
      brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
      brightcove_response = brightcove.post_file('create_video',
        File.join(File.dirname(__FILE__), 'assets', 'movie.mov'),
        :video => {:shortDescription => "Short Description", :name => "Video"})

      expect(brightcove_response).to have_key('result')
      expect(brightcove_response['result']).to eq(653155417001)
      expect(brightcove_response['error']).to be_nil
    end
  end

  it 'should allow you to create a video using #post_file_streaming' do
    VCR.use_cassette('post_file_streaming', :serialize_with => :yaml) do
      brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
      brightcove_response = brightcove.post_file_streaming('create_video',
        File.join(File.dirname(__FILE__), 'assets', 'movie.mov'), 'video/quicktime',
        :video => {:shortDescription => "Short Description", :name => "Video"})

      expect(brightcove_response).to have_key('result')
      expect(brightcove_response['result']).to eq(653155417001)
      expect(brightcove_response['error']).to be_nil
    end
  end


  it 'should allow you to create a video using #post_io_streaming' do
    VCR.use_cassette('post_file_streaming', :serialize_with => :yaml) do
      brightcove = Brightcove::API.new('0Z2dtxTdJAxtbZ-d0U7Bhio2V1Rhr5Iafl5FFtDPY8E.')
      brightcove_response = File.open(File.join(File.dirname(__FILE__), 'assets', 'movie.mov')) do |file|
        brightcove.post_io_streaming('create_video', file, 'video/quicktime',
          :video => {:shortDescription => "Short Description", :name => "Video"})
      end

      expect(brightcove_response).to have_key('result')
      expect(brightcove_response['result']).to eq(653155417001)
      expect(brightcove_response['error']).to be_nil
    end
  end

  it 'should allow you to create a video using #post_io_streaming with an HTTP source' do
    VCR.use_cassette('post_io_streaming_http', :serialize_with => :yaml) do
      brightcove = Brightcove::API.new('ZY4Ls9Hq6LCBgleGDTaFRDLWWBC8uoXQHkhGuDebKvjFPjHb3iT-4g..')
      brightcove_response = open('http://archive.org/download/SummerSFSunset/SummerSFSunset_512kb.mp4') do |file|
        brightcove.post_io_streaming('create_video', file, 'video/mp4',
                                     :video => {:shortDescription => "Short Description", :name => "Video"})
      end

      expect(brightcove_response).to have_key('result')
      expect(brightcove_response['result']).to eq(3088439142001)
      expect(brightcove_response['error']).to be_nil
    end
  end
end