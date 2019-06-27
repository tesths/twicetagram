# coding: utf-8
require 'json'
require 'httparty'

class Request

  def initialize(url, headers)
    @url = url
    @headers = headers
  end

  def setCode=(value)
    @code = value
  end

  def setBody=(value)
    @body = value
  end

  def setJson=(value)
    @json = value
  end

  def get_response
    puts "request start at " + Time.now.to_s
    begin  
      response = HTTParty.get(@url, headers: @headers, timeout: 60)
    rescue StandardError => e
      puts "StandardError " + e.to_s
      sleep(5)
      retry
    end
    self.setCode = response.code
    self.setBody = response.body
  end
  
  def check_response
    if @code.between?(400, 600)
      puts Time.now
      puts @code
      return false
    else
      return true
    end
  end

  def check_html
    begin
      data = @body.scan(/window._sharedData = (.*?);/)[0][0]
      @json = JSON.parse(data)
      self.setJson = @json
      return true
    rescue StandardError => e
      return false
    end
  end

  def check_json
    begin
      @json = JSON.parse(@body)
      self.setJson = @json
      return true
    rescue JSON::ParserError => e
      return false
    end
  end
end

class MHandle < Request
  # 列表请求 json
  def main_json
    puts "main_json response success! response code is " + @code.to_s
    return json
  end

  # 获取全部列表中第一个 code
  def get_code
    return @json["entry_data"]["ProfilePage"][0] \
            ["graphql"]["user"]["edge_owner_to_timeline_media"] \
            ["edges"][0]["node"]["shortcode"]
  end

  # 获取列表数量
  def get_count
    return @json["entry_data"]["ProfilePage"][0] \
            ["graphql"]["user"]["edge_owner_to_timeline_media"] \
            ["edges"].count
  end

  # 获取第一个的文字
  def get_text
    edges_count = @json["entry_data"]["ProfilePage"][0] \
            ["graphql"]["user"]["edge_owner_to_timeline_media"] \
            ["edges"][0]["node"]["edge_media_to_caption"] \
            ["edges"]
    if edges_count.length != 0
      byebug
      caption = edges_count[0]["node"]["text"]
      
      if caption.length > 105
        caption = caption[0..105] + "..."
      end
    else
      caption = ""
    end
    
    return caption
  end

  def get_shortcode_media
    return @json["graphql"]["shortcode_media"]
  end

  def get_count_str
    count_str = ""
    shortcode_media = @json["graphql"]["shortcode_media"]
    if shortcode_media.has_key? "edge_sidecar_to_children"
      edges = shortcode_media["edge_sidecar_to_children"]["edges"]
      v_count = 0
      p_count = 0 
      for edge in edges
        if edge["node"]["is_video"]
          v_count = v_count + 1
        else
          p_count = p_count + 1
        end
      end
      if v_count == 0
        count_str = "(" + p_count.to_s + "P" + ")"
      elsif p_count == 0
        count_str = "(" + v_count.to_s + "V" + ")"
      else
        count_str = "(" + p_count.to_s + "P" + v_count.to_s + "V" + ")"
      end
    else
      if shortcode_media["is_video"] == true
        count_str = "(1V)"
      else
        count_str = "(1P)"
      end
    end
    return count_str
  end

  def get_url_array
    url_array = []
    count = 0
    shortcode_media = @json["graphql"]["shortcode_media"]
    if get_shortcode_media.has_key? "edge_sidecar_to_children"
      data = get_shortcode_media["edge_sidecar_to_children"]["edges"]
      # 判断是否含有视频 如果第一个是视频 则只发视频
      if data[0]["node"]["is_video"] == true
        url = data[0]["node"]["video_url"]
        url_array.push(url)
      else
      # 第一个不是视频 则发出所有图片
        for data_det in data
          if data_det["node"]["is_video"] == false
            if count == 4
              break
            end
            url = data_det["node"]["display_resources"].last["src"]
            url_array.push(url)
            count = count + 1
          end
        end
      end
    else
      # 判断是否为单独 media 这里是单独一个
      if get_shortcode_media["is_video"] == true
        url = get_shortcode_media["video_url"]
        url_array.push(url)
      else
        url = get_shortcode_media["display_resources"].last["src"]
        url_array.push(url)
      end
    end
    return url_array
  end

end

class LHandle < Request
  # 详细信息请求 json
  def list_json
    puts "list_json response success! response code is " + @code.to_s
    begin
      json = JSON.parse(@body)
    rescue StandardError => e
      puts "StandardError " + e.to_s
    end
    return json
  end
end

class SHandle < Request
  def story_json
    puts "story_json response success! response code is " + @code.to_s
    begin
      json = JSON.parse(@body)
    rescue StandardError => e
      puts "StandardError " + e.to_s
    end
    return json
  end
end
