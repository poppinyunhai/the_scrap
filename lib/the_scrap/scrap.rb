# encoding: utf-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'pp'
require 'timeout'

module TheScrap
  class Scrap
    attr_accessor :item_frag #条目
    attr_accessor :url #起点URL
    attr_accessor :base_url #图片，连接base url
    attr_accessor :html_proc #获取页面html后的处理方法
    attr_accessor :data_proc #抓取完内容后手工对数据进行加工
    attr_accessor :result_proc #入库，文件生成等。
    attr_accessor :detail_info #详细页面对象

    attr_accessor :encoding

    attr_accessor :debug
    alias_method :debug?, :debug

    attr_accessor :verbose
    alias_method :verbose?, :verbose

    def initialize()
      @attrs = {}
      @more_info = []
      @debug = false
      #@encoding = 'utf-8'
      @result_proc = []
      @detail_info = []
      @data_proc = []
      @html_proc = []
    end

    def retryable( options = {} )
      opts = { :tries => 1, :on => Exception }.merge(options)

      retry_exception, retries = opts[:on], opts[:tries]

      begin
        return yield
      rescue retry_exception
        if (retries -= 1) > 0
          sleep 2
          retry 
        else
          raise
        end
      end
    end

    def method_missing( method_id, *arguments, &block )
      if(method_id =~ /attr_(.*)=/)
        name = $~[1]
        @attrs[name] = arguments.first
      end
    end

    protected
    #TODO document
    def get_attrs( url, doc, item_info )
      @attrs.keys.each do |k|
        unless @attrs[k].is_a? Array
          item_info[k] = doc.css(@attrs[k]).text.strip
        else
          option = @attrs[k]
          if option[0] == :frag_attr
            item_info[k] = doc[option[1]]
            next
          end

          node = doc.css(option[0]).first
          next unless node
          if(option[1] == :inner_html)
            item_info[k] = node.inner_html
          elsif(option[1] == :join)
            item_info[k] = doc.css(option[0]).map{|i|i.text}.join(',')
          elsif(option[1] == :array)
            item_info[k] = doc.css(option[0]).map{|i|i.text}
          else
            if [:href,:src].include? option[1].to_sym
              #why ???
              src = node[option[1]].strip.gsub(" ","%20")
              begin
                item_info[k] = URI.join(base_url||url,src).to_s  
              rescue
                item_info[k] = src.to_s
              end
            else
              item_info[k] = node[option[1]].strip
            end
          end
        end
      end
    end
  end
end

