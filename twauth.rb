#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'oauth'
require 'sqlite3'
require 'pp'
include SQLite3

class TWAuth
  SITE               = "https://api.twitter.com"

  attr_reader :consumer, :token, :filename

  def initialize( consumer_key, consumer_secret, filename )
    # 保存先ファイル名
    @filename = filename
    # consumer keyの取得
    @consumer = OAuth::Consumer.new(
                                    consumer_key,
                                    consumer_secret,
                                    :site => SITE
                                    )
    # access_token / access_token_secretのインスタンス変数への代入
    read_accesstoken
    # access_tokenの取得
    @token = OAuth::AccessToken.new(
                                    @consumer,
                                    @access_token,
                                    @access_token_secret
                                    )
  end

  private
  def read_accesstoken
    if !File.exist?( @filename )
#      puts "create configuration file ( #{@filename} )"
      create_newtable
      create_newtoken
#      puts "token  : #{@access_token}"
#      puts "secret : #{@access_token_secret}"
    else
#      puts "open configuration file ( #{@filename} )"
      db = Database.new( @filename )
      arr = db.execute( "SELECT access_token, access_token_secret FROM auth" )
      db.close
      if arr.length == 0 
        create_newtoken
      elsif arr.length == 1
        @access_token        = arr[0][0]
        @access_token_secret = arr[0][1]
      else
        raise "#{arr.length} access_token is found"
      end
#      puts "token  : #{@access_token}"
#      puts "secret : #{@access_token_secret}"
    end
  end

  def create_newtable
    db = Database.new( @filename )
    db.execute( "
CREATE TABLE auth (
   access_token text,
   access_token_secret text
 );")
    db.close
  end
  def create_newtoken
    db = Database.new( @filename )
    get_newtoken
    db.execute( "
INSERT INTO auth ( access_token, access_token_secret ) VALUES ( \"#{@access_token}\", \"#{@access_token_secret}\" );")
    db.close
  end

  def get_newtoken
    if @consumer == nil
      raise "Invalid Consumer Key/Secret"
    end

    begin
      begin
        puts "Twitterにアクセスするためのkeyを取得します。"
        req = @consumer.get_request_token
      rescue
        puts "失敗しました。インターネットへの接続を確認してください。"
        raise "Failure of getting a request_token"
      end

      puts "以下の手順に1,2に従ってください。"
      puts  "1: 以下のURLにアクセスしてPINコードを取得してください。"
      puts  "#{req.authorize_url}"
      puts  ""
      puts  "2: 以下に取得したPINコードを入力してください。"
      print "PINコード > "
      pin = gets.chomp
      acc = req.get_access_token( :oauth_verifier => pin )
      puts "token  : #{acc.token}"
      puts "secret : #{acc.secret}"
    rescue OAuth::Unauthorized
      puts "有効なPINコードを入力してください。"
      puts ""
      retry
    end

    puts "認証成功。"
    @access_token = acc.token
    @access_token_secret = acc.secret
  end
end

# auth = TWAuth.new
