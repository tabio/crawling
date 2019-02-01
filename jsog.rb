#!/usr/bin/env ruby
require 'nokogiri'
require 'pp'
require 'open-uri'
require 'csv'
require 'nkf'
require 'send_mail.rb'

class JSOG
  SLEEP_COOUNT = 10

  attr_reader :csv_result

  def initialize
    @csv_result = "reports/jsog_list_#{Time.now.strftime('%Y%m%d')}.csv"
    Dir::mkdir('reports') if !Dir.exist?('reports')
  end

  def mk_list
    base_url = 'http://www.jsog.or.jp/facility_program/search_result_facility.php?srf_pref_cd=%s'
    CSV.open(@csv_result, 'w') do |csv|
      csv << %w|都道府県 施設番号 施設名 専攻医指導施設 婦人科腫瘍登録施設 周産期登録施設 体外受精・胚移植の臨床実施に関する登録施設 ヒト胚および卵子の凍結保存と移植に関する登録施設 顕微授精に関する登録施設 医学的適応による未受精卵子、胚（受精卵）および卵巣組織の凍結・保存に関する登録施設 提供精子を用いた人工授精に関する登録施設|
      (1..47).each do |i|
        sleep SLEEP_COOUNT
        url = base_url % i
        doc = Nokogiri::HTML(open(url))
        doc.css('table#programtable tbody tr').each do |tr|
          res = tr.css('td').each_with_object([]) do |td, arr|
             arr << td.inner_text
          end
          csv << res
        end
      end
    end
  end
end

obj = JSOG.new
obj.mk_list

SendMail.send_csv('日本産婦人科科学会csv', obj.csv_result)
