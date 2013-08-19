#!/usr/bin/env ruby
# coding: utf-8

require 'rubygems'
require 'net/https'
require 'twitter'
require 'oauth'
require 'json'
require 'pp'
require 'thread'
require './twauth'

class InshiBot

  eval(%w(        CON
  SU    MER  _KEY="YXHQw99
  wM   bis   0p          oj
  ag   aP    CA ").join) #a
  eval(\
  %w(  CO      NSUMER_SE
  CRE   T=      "l   se
  f4f  Ij      uq     b7
  4Hey        RbD     aS4
  xLF        fbS       CN  Dw
  jze        FA3         jdo

").join)

   eval(%w(BOT_USER_AGENT
       ="        in
      shibot"    ).
    join   )     #yo   ss
   eval( %w(     HT   TP
   S   _ CA_     FI   LE
 _P     ATH      ="./
       twi       tt
     er.         ce
   r"            ).join) #ha



  # データ保存先ファイル名 -- sqlite3で保存
  DBFILENAME = "inshibot.sqlite3"

  @@deadline = Time.local( 2013, 8, 20, 9, 0, 0 )

  def initialize
    @auth = TWAuth.new( CONSUMER_KEY, CONSUMER_SECRET, DBFILENAME )
    @dbfile = DBFILENAME
  end

  @@first = true
  def run
    puts "Press Any Key for EXIT"
    t_key  = Thread.new {
      system("stty raw -echo") #=> Raw mode, no echo
      char = STDIN.getc
      system("stty -raw echo") #=> Reset terminal mode
    }
    t_twit = Thread.new {
      loop do
        begin
          if (diff = (@@deadline - Time.now)) > 0
            day = diff.divmod(60*60)
            min = day[1].divmod(60)
            post "院死(情報理工・専門)まで あと #{"%3d"%day[0].to_i} 時間! #inshibot" if day[1].to_i == 0 || @@first
            @@first = false
            print "\r院死(情報理工・専門)まで あと #{"%3d"%day[0].to_i} 時間 #{"%2d"%min[0].to_i} 分 #{"%2d"%min[1].to_i}秒! #inshibot"
            STDOUT.flush
          elsif diff == 0
            post "院死開始！！！！！ #inshibot"
            puts "院死開始！！！！！ #inshibot"
          else
            diff = -diff
            day=diff.divmod(60*60)
            min=day[1].divmod(60)
            post "院試(情報理工・専門)開始から #{"%2d"%day[0].to_i} 時間経過！ #inshibot" if day[1].to_i == 0 || @@first
            @@first = false
            print "\r院死(情報理工・専門)開始から #{"%3d"%day[0].to_i} 時間 #{"%2d"%min[0].to_i} 分 #{"%2d"%min[1].to_i}秒 経過! #inshibot"
            STDOUT.flush
          end
        rescue
          puts "#{$!}"
        end
        sleep 1
      end
    }
    t_key.join
    t_twit.kill
  end

  private
  def stream
    count = 0
    begin
      # jsonがパースされたものがブロック引数に来る
      connect do |msg|
        # pp msg
      end
    rescue Timeout::Error, StandardError
      puts "Error!!: #{$!}"
      sleep 1
      retry
    end
  end

  def find text, msg
    if msg['text']
      if msg['text'].include?( text )
        yield msg
        return true
      end
    end
    false
  end


  def connect
    uri = URI.parse("https://userstream.twitter.com/2/user.json?track=#{MY_SCREEN_NAME}")

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.ca_file = HTTPS_CA_FILE_PATH
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5

    pp https

    https.start do |https|
      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = BOT_USER_AGENT
      request.oauth!(https, @auth.consumer, @auth.token)

      buf = ""
      https.request(request) do |response|
        response.read_body do |chunk|
          buf << chunk
          # jsonのパース
          while(line = buf[/.+?(\r\n)+/m]) != nil
            begin
              buf.sub!(line,"")
              line.strip!
              status = JSON.parse(line)
            rescue
              break
            end
            yield status
          end
        end
      end
    end
  end

  def refollow msg
    if msg['event'] == "follow"
      puts "follow: #{msg['source']['screen_name']}(#{msg['source']['id']}) => #{msg['target']['screen_name']}(#{msg['target']['id']})"
      if msg['target']['screen_name'] == MY_SCREEN_NAME
        ret = @auth.token.post( '/1.1/friendships/create.json',
                         'user_id' => msg['source']['id'],
                         'follow'  => true
                         )
        if ret.class != Net::HTTPOK
          puts "refollow is failed: #{ret}"
        end
      end
    end
  end

  def post text, option={}
    param={}
    param[ :status ] = text
    param[ :in_reply_to_status_id ] = option[ :reply_id ] if option[ :reply_id ]
    ret = @auth.token.post('/1.1/statuses/update.json', param )
    if ret.class != Net::HTTPOK
      puts "Post ( #{text} ) is failed: #{ret}"
    else
      puts "success update! :: #{text}"
    end
  end

  def favorite msg
    return unless msg['text']
    param={}
    param[ :id ] = msg[ 'id' ]
    ret = @auth.token.post('/1.1/favorites/create.json', param )
    if ret.class != Net::HTTPOK
      puts "Favorite ( #{msg['text']} ) is failed: #{ret}"
    else
      puts "success favorite! :: #{msg['text']}"
    end
  end

  def print_post msg
    if msg['text']        # tweet
      puts "#{"%20s"%msg['user']['name']} -- #{"%15s"%msg['user']['screen_name']} : #{msg['text']}"
    end
  end

  def save_twit table, msg
    begin
      puts "open #{table}"
      db = SQLite3::Database.new( @dbfile )
      db.execute( "INSERT INTO #{table} ( twitid, text, name, screen_name, date ) VALUES ( ?,?,?,?,? );",
                 msg['id'], msg['text'], msg['user']['name'], msg['user']['screen_name'], msg['created_at'] )
      db.close
      puts "saved: ( #{msg['id']}, '#{msg['text']}', '#{msg['user']['name']}', '#{msg['user']['screen_name']}', '#{msg['created_at']}' )"
    rescue SQLite3::SQLException
      puts "Error in 'save_twit': #{$!}"
      puts "table: #{table} will create"
      db.execute( "
CREATE TABLE #{table} (
    id          integer PRIMARY KEY AUTOINCREMENT,
    twitid      integer,
    text        text,
    name        text,
    screen_name text,
    date        text
);")
      retry
    end
  end

  def get_db_randomly table
    begin
      db = SQLite3::Database.new( @dbfile )
#       twit = db.execute( "SELECT text, name, screen_name FROM #{table} ORDER BY RANDOM() LIMIT 1;" )
      twit = db.execute( "SELECT text, name, screen_name FROM #{table} as tbl, ( SELECT id FROM tsurai ORDER BY RANDOM() LIMIT 1 ) AS random WHERE tbl.id == random.id;" ) # こっちのほうがクエリの取得が早いみたい。
      db.close
      twit
    rescue
      puts "Error in 'get_db_randomly': #{$!}"
      raise "There is no data"
    end
  end
end

if $0 == __FILE__
  InshiBot.new.run
end
