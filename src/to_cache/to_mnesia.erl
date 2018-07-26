%%%-------------------------------------------------------------------
%%% @author yj
%%% @doc
%%%
%%% Created : 30. 五月 2018 下午3:12
%%%-------------------------------------------------------------------
-module(to_mnesia).

-define(no_cache_behaviour, 1).
-include("cache_pub.hrl").

-export([
    init/1,
    set/2,
    cache_data/4
]).


init(Config) ->
    ?mnesia_new(Config#cache_mate.name, Config#cache_mate.cache_copies, Config#cache_mate.type, Config#cache_mate.fields, Config#cache_mate.index).


%% @doc 同时插入两张表的情况
set(_Config, Items) -> [mnesia:dirty_write(Item) || Item <- Items].


cache_data(CacheConfig, _Md5, FileRecords, _AllData) ->
    if
        is_function(CacheConfig#cache_mate.callback) ->
            Records = (CacheConfig#cache_mate.callback)(FileRecords),
            [mnesia:dirty_write(Record) || Record <- Records];
        true ->
            ok
    end.