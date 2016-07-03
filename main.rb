require 'rubygems'
require 'json'
require 'json/pure'
require 'simple-rss'
require 'sanitize'
require 'open-uri'
require 'pry'

class TerminalRSSReader

  def main

    loop do
      read
      sleep(5)
    end

  end

  private

  def read

    feeds = JSON.load(File.open('feeds.json'))

    # ==========================================
    # lastから見ていく。
    # lastが新しければ、lastを書き換えて表示する
    # 表示したら、jsonのlatest_titleを書き換える
    # ==========================================
    feeds.each_with_index do |feed, i|
      rss = SimpleRSS.parse open(feed['url'])

      viewed_all = false
      k = rss.items.size - 1

      unless feed['latest_title'].empty?
        rss.items.reverse.each_with_index do |item, j|
          # latest_title＝最新のエントリだったらもう表示しない
          if item.title.force_encoding('UTF-8') == feed['latest_title']
            viewed_all = true if item.pubDate == rss.items.first.pubDate

            k = rss.items.size - (j + 2)
            break
          end
        end
      end

      unless viewed_all
        description = JSON.utf8_to_json_ascii(rss.items[k].description)

        # ==================================================================
        # TODO 画像出したい
        # LifeHackerは画像が入ってるっぽいのでHTMLタグを消す前に抽出しておく
        # ==================================================================
        # if description.match(/(http.+.(gif|png|jpg))/)
        #   image_url = description.match(/(http.+.(gif|png|jpg))/)[1]
        # else
        #   image_url = ""
        # end

        # ==============
        # 表示内容の用意
        # ==============
        title = rss.items[k].title
        pubdate = rss.items[k].pubDate
        link = rss.items[k].link
        description = Sanitize.clean(JSON.parse( %Q{["#{description}"]} )[0])
        description = description.gsub(/(\n|\t|\\n|\\t|\\r\\n| )/,"")

        # ================
        # コンソールに表示
        # ================
        puts "========== #{pubdate} =========="
        puts "■#{title.force_encoding('UTF-8')}"
        puts "　#{link}"
        # TODO 画像出したい
        # puts "　#{image_url}"
        puts "　#{sanitize(description)}"
        puts ""
        puts ""


        # ========================
        # jsonのlatest_titleを書き換える
        # ========================
        feeds[i]['latest_title'] = rss.items[k].title
        File.write('feeds.json', feeds.to_json)
      else
        # ==============================
        # このフィードを読了しているとき
        # =============================
        puts "新しい記事はありません。"
        exit
      end
    end

  end

  def sanitize(description)
    description.gsub(/記事を読む$/, "")
  end

end

hoge = TerminalRSSReader.new
hoge.main

