## mnesia_cache-数据缓存
> * 缓存使用ets，算不上一个真正的缓存系统

## config-数据缓存

### 
> * 缓存使用ets
> * 支持多种文件格式拓展，目前支持mysql
> * 数据热更新,目前简单粗暴，没有做任何容错处理


###todo_list

> * 支持txt,xml,json格式解析,以及excle解析


### 重构功能

> * ets 各个application 加载各自的ets，不再使用cache application 加载 防止报错
> * 支持持久化 mnesia
> * 支持数据源：RDB，文档
> * 加载数据
