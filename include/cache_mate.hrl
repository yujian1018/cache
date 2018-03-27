%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 26. 十月 2017 下午12:25
%%%-------------------------------------------------------------------

-define(cache_behaviour, cache_behaviour).

-define(cache_tab_md5, cache_tab_md5).

-record(cache_mate, {
    name = none :: atom(),
    record = none :: tuple(),       % 默认建立ets表;当有值时，读取数据
    table_type = set :: set|bag,
    key_pos = 2 :: integer(),
    
    type = mysql :: atom(), %文件类型， mysql、txt、json、xml、excle
    %% 当type=mysql,file=database_name
    file = none,
    mysql_pool = pool_static_1 :: atom(),
    fields :: list(),
    
    rewrite = none :: fun(),    %数据格式重写
    verify = none :: fun(),  %fun() -> boolean().
    all = [2] :: [integer()], %默认把该表的所有key值维护去来，用来热更数据时使用
    
    group = [] :: [integer()],   %
    
    priority = 1    %数据加载优先级,越小越优先加载
}).



-ifndef(no_cache_behaviour).

-behaviour(?cache_behaviour).
-export([load_cache/0]).

-endif.
