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
#表示，表格的每一行，或者列表的每个元素
#这个行或者元素里面应该包含这条记录的详细信息
#详细信息通过attr列表来获取。
scrap.item_frag = ".layoutlist .list-bigpic"

#scrap attr list
scrap.attr_name = ['.ft-tit',:inner_html]
scrap.attr_detail_url = ['.ft-tit',:href]
scrap.attr_img = ['dt a img',:src]
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

##### 此处可以添加 多页分页 抓取功能 参见 2

##### 此处可以添加 详细信息页面 抓取功能 参见 3

#scrap
scrap.scrap_list

```

### 1. 列表抓取

参考上一节

### 2. 多页列表抓取

```ruby

#create ListObj

#...

########### has many pages ###########
#如果设置了可以根据不同的分页方式抓取多页列表

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
#...

scrap.scrap_list

```

### 3. 带详细页面信息提取

```ruby

#create ListObj
...

################# has detail page ################
#如果设置了可以根据之前抓取的详细页面URL获取详细页面信息

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

#...

scrap.scrap_list

```


### 4. 元素属性说明

元素属性使用 scrap.attr_#{元素名称} = 规则 来表示

抓取后将全部放到一个Hash中，其中“元素名称”为Hash的Key，获取的数据为Hash的值
如：scrap.attr_name = ".title" 则结果item['name'] = ".title 对应的节点内容"

其中规则可以使用多种方式表示
#### 4.1 直接使用CSS Selector
	
直接使用CSS Selector的情况下，则取得CSS节点对应的 文本内容（inner_text)

#### 4.2 一个数组

scrap.attr_name = [css_selector,attrs]

其中数值的第一个元素为： css_selector

第二个元素可选值为：

1. frag_attr

直接去Fragmengt的属性，如list的属性,因为在实际使用过程中遇到过需要取列表或表格行的某个属性的情况。

scrap.attr_name = [:frag_attr,'href']

数组第一个元素为frag_attr而非css selector因为css selector 已经在 scrap.item_frag 中指定，此为特例仅此一处出现此用法。

2. inner_html 

取节点内的html

3. join

遇到某个list时，需要把里面的元素全部获取并使用逗号分隔。如：tags

```html
<ul class=".tags">
<li>ruby</li>
<li>rails</li>
<li>activerecord</li>
</ul>
```

```ruby
scrap.attr_name = ['.tags', :join]
```

使用上述取得一个字符串: “ruby,rails,activerecord"

4. array

遇到某个list时，需要把里面的元素全部获取并返回一个Array

```html
<ul class=".tags">
<li>ruby</li>
<li>rails</li>
<li>activerecord</li>
</ul>
```

```ruby
scrap.attr_name = ['.tags', :array]
```

使用上述取得一个字符串: ['ruby','rails','activerecord']

5. src

取得图片的SRC属性，并且使用URI.join(current_page_url,src_value)

6. href

取得链接的href属性，并且使用URI.join(current_page_url,href_value)

7. "else"

直接获取元素属性的，不做任何其他处理。


``ruby`
scrap.attr_name = ['.ft-tit',:inner_html]
scrap.attr_detail_url = ['.ft-tit',:href]
scrap.attr_img = ['dt a img',:src]
scrap.attr_desc = '.feature p'
scrap.attr_price = '.fc-org'
``


### 5. 分页模式

参考 2. 多页列表抓取

### 6. 处理方法

TODO


### 7. 结果处理

#### mysql
```ruby
require 'active_record'
require 'mysql2'
require 'activerecord-import' #recommend


ActiveRecord::Base.establish_connection( :adapter => "mysql2",  :host => "localhost",
 :database => "test", :username => "test", :password => ""  )

ActiveRecord::Base.record_timestamps = false
class Article < ActiveRecord::Base
  validates :ori_id, :uniqueness => true
end

# OR load Rails env!

scrap.result_proc << lambda {|url,items|
  articles = []
  items.each do |item| 
		#item[:user_id] = 1
		articles << Article.new(item)
	end
  Article.import articles
}
```
#### mongodb

```ruby
require 'mongoid'

Mongoid.load!("./mongoid.yml", :production)
Mongoid.allow_dynamic_fields = true

class Article
  include Mongoid::Document
	#....
end

# OR load Rails env!

scrap.result_proc << lambda {|url,items|
  items.each do |item| 
		#item[:user_id] = 1
		Article.create(item)
	end
}
```

### json,xml...

```ruby
#json
scrap.result_proc << lambda {|url,items|
	File.open("xxx.xml",'w').write(items.to_json)
}

#xml
scrap.result_proc << lambda {|url,items|
	articles = []
  items.each do |item| 
		articles << item.to_xml
	end
	file  = File.open("xxx.xml",'w')
	file.write('<articles>')
	file.write(articles.join(''))
	file.write('</articles>')
	file.close
}
```

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

