## The Scrap

The Scrap 是一个基于Nokogiri的网页数据抓取的框架，目标是使用简单、高效、高自定义、高适配性。

代码从个人项目ODSHUB提取出来，集合近10年来无聊时抓取数据的经验（请自动忽略本句吹牛语），


## Installation

Add this line to your application's Gemfile:

    gem 'the_scrap'

And then execute:

    $ bundle    

Or install it yourself as:

    $ gem install the_scrap

## Usage
### 0. 全景


```ruby

# encoding: utf-8
require 'rubygems'
require 'the_scrap'
require 'pp'

#create Object
scrap = TheScrap::ListObj.new

#set start url
scrap.url = "http://fz.ganji.com/shouji/"

#fragment css selector
scrap.item_frag = ".layoutlist .list-bigpic"

#scrap attr list
scrap.attr_name = ['.ft-tit',:inner_html]
scrap.attr_detail_url = ['.ft-tit','href']
scrap.attr_img = ['dt a img','src']
scrap.attr_desc = '.feature p'
scrap.attr_price = '.fc-org'

#debug
scrap.debug = true
scrap.verbose = true


#html preprocess
scrap.html_proc << lambda { |html|
  #html.gsub(/abcd/,'efgh')
}

#filter scraped item
scrap.item_filters << lambda { |item_info| 
  return false if item_info['name'].nil? || item_info['name'].length == 0
  return true
}

#data process
scrap.data_proc << lambda {|url,i|
  i['name'] = i['name'].strip
}

#result process
scrap.result_proc << lambda {|url,items|
  items.each do |item| 
    pp item
  end
}

########### has many pages ###########
#如果设置了可以根据不同的分页方式抓取多页列表

=begin

scrap.has_many_pages = true

#next page link

# [:next_page, :total_pages, :total_records]


#:next_page
scrap.page_method = :next_page
scrap.next_page_css = ".next_page a"


#:total_page
scrap.page_method = :total_pages
scrap.get_page_count = lambda { |doc|
  if doc.css('.total_p[age').text =~ /(\d+)页/
    $~[1].to_i
  else
    0
  end
}

scrap.get_next_url = lambda { |url,next_page_number|
  #url is  http://fz.ganji.com/shouji/
  #page url pattern http://fz.ganji.com/shouji/o#{page_number}/
  url += "/o#{next_page_number}"
}

#**total_record in progress
scrap.page_method = :total_records

=end

################# has detail page ################
#如果设置了可以根据之前抓取的详细页面URL获取详细页面信息

=begin
#1. define a detail object
scrap_detail = TheScrap::DetailObj.new
scrap_detail.attr_title = ".Tbox h3"
scrap_detail.attr_detail = ".Tbox .newsatr"
scrap_detail.attr_content = [".Tbox .view",:inner_html]


#optional html preprocess
scrap_detail.html_proc << lambda{ |response|
}

#optional data process
scrap_detail.data_proc << lambda {|url,i|
}

#optional result process
scrap_detail.result_proc << lambda {|url,items|
}

#get url from list attr and extra data by scrap_detail
scrap.detail_info << [scrap_detail,'detail_url']

#scrap.detail_info << [scrap_detail_1,'detail_url_1']

=end

#scrap
scrap.scrap_list

```

### 1. 列表抓取

TODO

### 2. 多页列表抓取

TODO

### 3. 带详细页面信息提取

TODO

### 4. 元素属性说明

TODO


### 5. 分页模式

TODO

### 6. 处理方法

TODO


### 7. 结果处理

TODO

## TODO

1. 多线程抓取
2. 线程管理
3. 完善文档


## Contributing

1. Fork it ( https://github.com/[my-github-username]/thescrap/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

