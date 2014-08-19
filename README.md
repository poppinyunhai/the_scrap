## The Scrap

The Scrap 是一个基于Nokogiri的网页数据抓取的框架

目标是使用简单、高效、高自定义、高适配性。

## Why

**网页数据的抓取最基本的工作流程为：**

1. 确定要抓取的起始URL，如: https://ruby-china.org/topics
2. 抓取列表信息，一般列表信息按照tr,li,div,dd等呈现，每个节点为一条记录，如：上述URL中的Css Selector为：".topics .topic"
3. 提取记录的相关信息，标题，作者，分类，详细页面的URL等。
4. 抓取详细页面信息，一般列表只有部分信息，完整获取需要进入详细页面进行数据提取。
5. 数据源有分页的情况还需要循环抓取多页信息。
6. 数据加工。
7. 数据入库或输出,排重处理等。


**在处理以上任务是往往会遇到如下问题：**

1. 源HTML无法直接使用，需要进行一些处理
2. 抓取的条目需要过滤无效数据。
2. 需要对住区的各种URL进行处理，如：连接或者图片往往不是完整的URL，需要通过当前页面地址进行合并处理。
3. 提取的数据需要进行特殊处理。还是RubyChina的例子比如帖子阅读次数：".info leader" 下的内容为：	"· 618 次阅读",需要的只是：618
4. 每个网站都有不同的分页机制，和分页URL的规则，处理起来相当麻烦。
5. 输出过程往往需要将之前提取的单个信息组合成一个对象或者Hash等。

**很久之前使用Perl进行数据抓取，由于个人Perl水平问题和语言上的一些限制，处理起来偏麻烦。后来用了很多Ruby写的框架都不是很满意(Scrubyt应该是我用过的比较不错的一个）**
**故根据实际需要慢慢总结形成了现在的方式：**

1. 定义列表和详细页面抓取规则
2. 需要提取的信息和提取规则通过Method missing方式存入Hash中。
3. 规则可以根据需要提取不同属性和数据，Link的href和IMG的src自动进行URI.join(current_url)处理
4. 实现列表多个节点的Join或者返回Array,如tags。
5. 实现多种分页方式支持。
6. 自动通过抓取列表数据取得的详细页面地址抓取详细信息，并合并到同一个结果记录中。
7. 抓取的结果为一个Hash，适当定义名称可以直接使用各种ORMapping实现进行入库，无需重新组装。
7. 使用Ruby的lambda实现Html处理、数据过滤、结果处理等，自定义程度和适应性有所提高。

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

**如果DetailObj不是单独运行而是在ListObj中运行，抓取的信息将合并到ListObj的结果中去**

```ruby

#create ListObj

#extra detail page url
scrap.attr_detail_url = [".list a",:href]

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
#此处可选，抓取的信息将合并到列表页面抓取的记录中去，也可以单独入库了。
scrap_detail.result_proc << lambda {|url,items|
}

#get url from list attr and extra data by scrap_detail
scrap.detail_info << [scrap_detail,'detail_url']

#scrap.detail_info << [scrap_detail_1,'detail_url_1']

#...

scrap.scrap_list

```


### 4. 元素属性说明

元素属性使用 **scrap.attr_#{元素名称} = 规则** 来表示

**抓取后将全部放到一个Hash中，其中“元素名称”为Hash的Key，获取的数据为Hash的值**

如

	scrap.attr_name = ".title"

则结果item['name'] = ".title 对应的节点内容"

其中规则可以使用多种方式表示

#### 4.1 直接使用CSS Selector
	
直接使用CSS Selector的情况下，则取得CSS节点对应的 文本内容（inner_text)

```ruby
@book_info.attr_author = "#divBookInfo .title a"
```

#### 4.2 一个数组

scrap.attr_name = [css_selector,attrs]

其中数值的第一个元素为： css_selector

第二个元素可选值为：

**:frag_attr**

直接去Fragmengt的属性，如list的属性,因为在实际使用过程中遇到过需要取列表或表格行的某个属性的情况。

scrap.attr_name = [:frag_attr,'href']

数组第一个元素为frag_attr而非css selector因为css selector 已经在 scrap.item_frag 中指定，此为特例仅此一处出现此用法。

**:inner_html**

取节点内的html

**:join**

遇到某个list时，需要把里面的元素全部获取并使用逗号分隔。如：tags

```html
<ul class="tags">
<li>ruby</li>
<li>rails</li>
<li>activerecord</li>
</ul>
```

```ruby
scrap.attr_name = ['.tags', :join]
```

使用上述取得一个字符串:

```ruby
"ruby,rails,activerecord"
```

**:array**

遇到某个list时，需要把里面的元素全部获取并返回一个Array

```html
<ul class="tags">
<li>ruby</li>
<li>rails</li>
<li>activerecord</li>
</ul>
```

```ruby
scrap.attr_name = ['.tags', :array]
```

使用上述取得一个字数组:

```ruby
['ruby','rails','activerecord']
```

**:src**

取得图片的SRC属性，并且使用URI.join(current_page_url,src_value)

**:href**

取得链接的href属性，并且使用URI.join(current_page_url,href_value)

**"else"**

直接获取元素属性的，不做任何其他处理。


**实例**

```ruby
@book_info = TheScrap::DetailObj.new
@book_info.attr_name = "#divBookInfo .title h1"
@book_info.attr_author = "#divBookInfo .title a"
@book_info.attr_desc = [".intro .txt",:inner_html]
@book_info.attr_pic_url = ['.pic_box a img',:src]
@book_info.attr_chapters_url = ['.book_pic .opt li[1] a',:href]
@book_info.attr_book_info = ".info_box table tr"
@book_info.attr_cat_1 = '.box_title .page_site a[2]'
@book_info.attr_tags = ['.book_info .other .labels .box[1] a',:array]
@book_info.attr_user_tags = ['.book_info .other .labels .box[2] a',:join]
@book_info.attr_rate = '#bzhjshu'
@book_info.attr_rate_cnt = ["#div_pingjiarenshu",'title']
@book_info.attr_last_updated_at ="#divBookInfo .tabs .right"
@book_info.attr_last_chapter = '.updata_cont .title a' 
@book_info.attr_last_chapter_desc = ['.updata_cont .cont a',:inner_html]
```

### 5. 分页模式

参考 2. 多页列表抓取

### 6. 获取的记录处理方法

可以多获取的结果进行处理后再执行入库操作：

简单举例：

```ruby
baidu.data_proc << lambda {|url,i|
  i['title'] = i['title'].strip
  if i['ori_url'] =~ /view.aspx\?id=(\d+)/
    i['ori_id'] = $~[1].to_i
  end

  if i['detail'] =~ /发布时间：(.*?) /
    i['updated_at'] = i['created_at'] = $~[1]
  end

  if i['detail'] =~ /来源：(.*?)作者：/
    i['description'] = $~[1].strip
  end

  i.delete('detail')
  
  i['content'].gsub!(/<script type="text\/javascript">.*?<\/script>/m,'');
  i['content'].gsub!(/<style>.*?<\/style>/m,'');
  i['content'].gsub!(/<img class="img_(sina|qq)_share".*?>/m,'');
  if i['content'] =~ /image=(.*?)"/
    #i['image'] = open($~[1]) if $~[1].length > 0
  end

  i['site_id'] = @site_id
  i['cat_id'] = @cat_id

  time = Time.parse(i['updated_at'])
  prep = '['+time.strftime('%y%m%d')+']'
}
```

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
	File.open("xxx.json",'w').write(items.to_json)
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

