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
          case event.message['text']
          when "あ"
            message = {
              type: 'text',
              text: "「あ」は一番しょうもないで。"
            }
          when "dog"
            message = {
              type: 'text',
              text: "犬"
            }
          when "cat"
            message = {
              type: 'text',
              text: "ねこ"
            }
          when "egg"
            message = {
              type: 'text',
              text: "卵"
            }
          when "bag"
            message = {
              type: 'text',
              text: "カバン"
            }
          when "fish"
            message = {
              type: 'text',
              text: "魚"
            }
          when "fruit"
            message = {
              type: 'text',
              text: "果物"
            }
          when "flower"
            message = {
              type: 'text',
              text: "花"
            }
          else
            message = {
              type: 'text',
              text: "ん？なんか言った？"
            }
          end
          client.reply_message(event['replyToken'], message)

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
