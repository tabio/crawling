#!/usr/bin/env ruby

require 'nokogiri'
require 'pp'
require 'open-uri'
require 'csv'
require 'nkf'

class Shusanki
  SLEEP_COOUNT = 1

  def initialize
    @site_url = 'http://shusanki.org/'
    @csv_pref = 'shusanki_pref.csv'
    @csv_city = 'shusanki_city.csv'
    @csv_target = 'target_list.csv'
  end

  def mk_pref_list
    url = "#{@site_url}area.html"
    csv.open(@csv_pref, 'w') do |csv|
      doc = Nokogiri::HTML(open(url))
      doc.css('dl#top a').each do |element|
        href = element[:href]
        next if href =~ /\A#{@site_url}/
        csv << [element.inner_text, "#{@site_url}#{href}"]
      end
    end
  end

  def mk_city_list
    CSV.open(@csv_city, 'w') do |csv|
      CSV.foreach(@csv_pref, headers: false) do |data|
        sleep SLEEP_COOUNT
        p data
        doc = Nokogiri::HTML(open(data[1]))
        doc.css('dl#area a').each do |element|
          csv << [element.inner_text, element[:href]]
        end
      end
    end
  end

  def mk_target_list
    CSV.open(@csv_target, 'w') do |csv|
      CSV.foreach(@csv_city, headers: false) do |data|
        sleep SLEEP_COOUNT
        p data
        doc = Nokogiri::HTML(open(data[1]))
        doc.css('div#contentsBox').each do |element|
          element.children.each do |child|
            next if child[:class] !~ /\Abg/
            info = child.css('p.info')
            name = info.css('a strong').inner_text
            link = info.css('a').attribute('href').value
            csv << [name, link]
          end
        end
      end
    end
  end

  def mk_list
    CSV.open('shusanki_list.csv','w') do |csv|
      csv << %w|施設名 参照元URL 郵便番号 住所 電話番号 URL|
      CSV.foreach(@csv_target, headers: false) do |data|
        sleep SLEEP_COOUNT
        p data
        doc = Nokogiri::HTML(open(data[1]))
        post = address = tel = url = ''
        doc.css('table#hospital tr td').each_with_index do |element, i|
          val = element.inner_text
          case i
          when 0
            post = val
          when 1, 2
            address += val
          when 3
            tel = val
          when 4
            url = val
          end
        end
        csv << data + [post, address, tel, url]
      end
    end
  end
end

obj = Shusanki.new
obj.mk_list
