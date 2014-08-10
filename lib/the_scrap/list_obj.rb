# encoding: utf-8
module TheScrap
  class ListObj < Scrap
    attr_accessor :item_filters #条目过滤
    attr_accessor :has_many_pages #是否多页
    attr_accessor :pager_method #分页模式
    attr_accessor :next_page_css #下一页模式时取下一页链接的 css selector
    attr_accessor :get_page_count #总页数模式时取总页数方法,不用CSS因为很可能需要重新处理数字。
    attr_accessor :get_next_url #总页数模式时，下一页的URL生成方式，方法

    def initialize()
      super
      @item_filters = []
    end

    def scrap( url )
      items = []

      html = open(url)
      html_proc.each do |dp|
        html = dp.call(html)
      end

      doc = Nokogiri::HTML( html )
      doc.css(item_frag).each do |item|

        item_info = {}
        get_attrs(url,item,item_info)

        #filter items
        need_skip = false
        item_filters.each do |filter|
          unless filter.call(item_info)
            need_skip = true
            break
          end
        end
        next if need_skip

        #has detail page?
        detail_info.each do |detail|
          detail[0].scrap(item_info[detail[1]],item_info)
        end

        #proc result
        data_proc.each do |dp|
          dp.call(url,item_info)
        end

        items << item_info

        pp item_info if debug?
        break if debug?
      end

      result_proc.each do |rp|
        rp.call(url,items)
      end

      return doc,items
    end

    def scrap_list
      doc,items = retryable(:tries => 3, :on => Timeout::Error) do
        scrap(url)
      end

      return unless has_many_pages

      #TODO Refactor it
      next_page_url = nil
      if pager_method == :next_page #有下一页连接的方式
        while node = doc.css(next_page_css).first
          next_page_url = URI.join(next_page_url||url,node['href']).to_s
          puts next_page_url if verbose?
          doc,items = retryable(:tries => 3, :on => Timeout::Error) do
            scrap(next_page_url)
          end
          break if items.count == 0
          break if debug?
        end
      elsif pager_method == :total_pages #可以获取总页数的方式,start by 1
        page_cnt = get_page_count.call(doc)
        (2..page_cnt).each do |idx|
          next_page_url = get_next_url.call(url,idx)
          puts next_page_url if verbose?
          doc,items = retryable(:tries => 3, :on => Timeout::Error) do
            scrap(next_page_url)
          end
          break if items.count == 0
          break if debug?
        end
      elsif pager_method == :total_records
        #TODO
        #可以取到总条数的方式 , 其实也可以使用上一方式(总页数）实现,只是在外部先使用总条数计算一下总页数
      end
    end
  end
end

