require 'net/http'
require 'uri'
require 'json'
require 'line/bot'
#LINEのライブラリをとる。

class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def ja? input
    input == "ja"
  end

  ADDRESS = URI.parse('https://www.googleapis.com/language/translate/v2')
  KEY = "AIzaSyApmeNSzPpRi_1LEP2zFT7l-DIKIibVF18"

  def translate q #単なる他の引数の書き方
    # ADDRESS = URI.parse('https://www.googleapis.com/language/translate/v2')
    params = {
      q: q,
      target: "ja",
      # source: "en"  ここを止めたらレベル３まで行けた。公式ドキュメント参考になった。ログデータを吐き出させて範囲を絞っていくと良い。
      key: KEY
    }
    ADDRESS.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(ADDRESS)
    input_langage = JSON.parse(res.body)["data"]["translations"].first["detectedSourceLanguage"]

    #日本語が入力されたときに英語を返す
    if ja?(input_langage)
      # logger.debug(result)
      params["target"] = "en"
      ADDRESS.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(ADDRESS)
    end

    result = JSON.parse(res.body)["data"]["translations"].first["translatedText"]
  end


  def callback
    #LINEのメッセージAPIがpostしてきた中身が取れる
    body = request.body.read

    #LINEからのアクセスかどうか調べる
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
             type: 'text',
             text: ""
          }
          message["text"] = translate event.message['text']
          client.reply_message(event['replyToken'], message)

        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    }
    head :ok
  end
end
