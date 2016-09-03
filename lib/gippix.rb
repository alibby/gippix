require 'ostruct'
require 'nokogiri'
require 'date'

# GPX
# http://www.topografix.com/GPX/1/1/
#
# Endeavoring to be a full GPX parser/ writer.

class Gippix
  class UnknownFileType < StandardError; end
  class ParseError < StandardError; end

  class Point < Struct.new :lat, :lon, :elevation, :time
    def to_s
      "POINT(%s %s %s)" % [ lon, lat, elevation ]
    end
  end


  def self.parser(file_name)
    parser_class_for_file(file_name).new(file_name)
  rescue Errno::ENOENT => e
    raise ParseError.new(e.to_s)
  end

  def self.parser_class_for_file(file_name)
    {
      'gpx' => Gpx
    }[ File.extname(file_name)[1..-1].downcase ] || raise(UnknownFileType.new(file_name))
  end

  ##########################################################################################
  class Base
    attr_accessor :doc, :file_name, :name, :description, :points

    def initialize(file_name)
      @file_name = file_name
      @doc = Nokogiri::XML( File.read file_name )
      @points = []
    end

    def with xpath, &blk
      yield @doc.xpath(xpath)
    end
  end

  ##########################################################################################
  class GpxGenerator
    attr_reader :builder

    def initialize
      @builder = Builder::XmlMarkup.new(:indent => 2)
    end

    def build(points)
      gpx_url = 'http://www.topografix.com/GPX/1/1'

      gpx_params = {
        :version => "1.1",
        :creator => 'Zugunroute Mobile http://zugunroute.com',
        :'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        :'xmlns' => gpx_url,
        :'xsi:schemaLocation' => "#{gpx_url} #{gpx_url}/gpx.xsd"
      }

      builder.gpx( gpx_params ) { |gpx|
        gpx.metadata { |meta|
          meta.name "joe"
          meta.desc "Mamma"
          meta.author { |a|
            a.name "Zugunroute"
            a.email :id => 'support', :domain => 'zugunroute.com'
          }
          meta.copyright(:author => "xforty technologies") { |copy| copy.year "2012" }
          meta.link(:href => "http://zugunroute.com") { |link|
            link.text "Zugunroute"
            link.type "text/html"
          }

          meta.time DateTime.now.strftime("%Y-%m-%d-T%H:%M:%SZ")
        }

        gpx.trk { |trk|
          trk.trkseg { |seg|
            points.each { |ll|
              seg.trkpt(:lat => ll.lat, :lon => ll.lon) { |pt|
                pt.ele ll.elevation
                pt.time DateTime.parse(ll.timestamp)
              }
            }
          }
        }
      }
    end

    def write_to_tempfile
      file = Tempfile.new(['activity','.gpx'])

      file.puts %Q{<?xml version="1.0" encoding="UTF-8"?>}
      file.puts builder.target!
      file.flush
      file
    end
  end
  ##########################################################################################
  class Gpx < Base

    def parse
      return self if @doc.nil?

      @description = @name = @doc.xpath('//xmlns:gpx/xmlns:trk[1]/xmlns:name').inner_text

      @points = parse_points
      @doc = nil

      self
    rescue Nokogiri::XML::XPath::SyntaxError
      raise ParseError.new("Could not find appropriate gpx root element")
    end

    def parse_points
      doc.xpath('//xmlns:gpx/xmlns:trk//xmlns:trkpt').map { |pt|
        Point.new(
          pt['lat'].to_f, pt['lon'].to_f,
          pt.xpath('xmlns:ele').inner_text.to_f,
          parse_date(pt.xpath('xmlns:time'))
        )
      }
    end

    def parse_date(doc)
      DateTime.parse doc.inner_text rescue nil
    end
  end
end
