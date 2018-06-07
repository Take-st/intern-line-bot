require 'active_support'
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

  def pluralize(word)
    return word.pluralize
  end


  def reply(input, token)
    message = {
      type: 'text',
      text: ""
    }

    case input
    when "あ"
      message['text'] = "あ は一番しょうもないで。"
    when "a"
      message['text'] = "a は一番しょうもないで。"
    when "dog", pluralize("dog")
      message['text'] = "犬"
    when "cat", pluralize("cat")
      message['text'] = "ねこ"
    when "egg", pluralize("egg")
      message['text'] = "卵"
    when "bag", pluralize("bag")
      message['text'] = "カバン"
    when "fish", pluralize("fish")
      message['text'] = "魚"
    when "fruit", pluralize("fruit")
      message['text'] = "果物"
    when "flower", pluralize("flower")
      message['text'] = "花"
    else
      message['text'] = "Could you please speak English?"
    end

    client.reply_message(token, message)
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

          reply(event.message['text'], event['replyToken'])

          # logger.debug(event.type)  #detect the type of the data
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
