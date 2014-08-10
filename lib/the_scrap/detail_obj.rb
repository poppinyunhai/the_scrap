# encoding: utf-8
module TheScrap
  class DetailObj < Scrap
    def scrap( url, item_info )
      return retryable(:tries => 3, :on => Timeout::Error) do
        do_scrap(url,item_info)
      end
    end

    def do_scrap( url, item_info )
      html = open(url).read
      html_proc.each do |dp|
        html = dp.call(html)
      end

      doc = Nokogiri::HTML(html)
      get_attrs(url,doc,item_info)

      #has detail page?
      #可以递归下层
      detail_info.each do |detail|
        detail[0].scrap(item_info[detail[1]],item_info)
      end

      #proc data
      data_proc.each do |dp|
        dp.call(url,item_info)
      end

      #proc result
      #此处可以单独指定对明细信息的入库处理
      result_proc.each do |rp|
        rp.call(url,[item_info])
      end

      pp item_info if debug?
      return item_info
    end
  end
end

