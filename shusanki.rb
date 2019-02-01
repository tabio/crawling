#!/usr/bin/env ruby

require 'nokogiri'
require 'pp'
require 'open-uri'
require 'csv'
require 'nkf'
require 'mail'
require './send_mail.rb'

class Shusanki
  SLEEP_COOUNT = 10

  attr_reader :csv_result

  def initialize
    @site_url = 'http://shusanki.org/'
    @csv_pref = 'shusanki_pref.csv'
    @csv_city = 'shusanki_city.csv'
    @csv_target = 'target_list.csv'
    @csv_result = "reports/shusanki_list_#{Time.now.strftime('%Y%m%d')}.csv"

    Dir::mkdir('reports') if !Dir.exist?('reports')
    mk_pref_list if !File.exist?(@csv_pref)
  end

  def mk_pref_list
    url = "#{@site_url}area.html"
    CSV.open(@csv_pref, 'w') do |csv|
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
  rescue => e
    p e.message
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
  rescue => e
    p e.message
  end

  def mk_list
    CSV.open(@csv_result,'w') do |csv|
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
  rescue => e
    p e.message
  end

  def clean
    File.delete(@csv_city)
    File.delete(@csv_target)
  rescue => e
    p e.message
  end
end

obj = Shusanki.new
obj.mk_city_list
obj.mk_target_list
obj.mk_list
obj.clean

SendMail.send_csv('周産期医療の広場csv', obj.csv_result)
