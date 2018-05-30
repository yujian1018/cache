%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 04. 十二月 2015 上午11:44
%%%-------------------------------------------------------------------
-module(cache_behaviour).

-callback load_cache() -> [] | [tuple()].

-define(no_cache_behaviour, 1).
-include("cache_pub.hrl").

-export([
    init/1,
    load_file/1,
    cache_data/3
]).

init(CacheConfig) when CacheConfig#cache_mate.cache_type =:= ets -> to_ets:init(CacheConfig);
init(CacheConfig) when CacheConfig#cache_mate.cache_type =:= mnesia -> to_mnesia:init(CacheConfig).


load_file(CacheConfig) when CacheConfig#cache_mate.type =:= mysql ->
    aof_mysql:load_file(CacheConfig).


cache_data(CacheConfig, FileRecords, AllData) when CacheConfig#cache_mate.cache_type =:= ets ->
    to_ets:cache_data(CacheConfig, FileRecords, AllData);
cache_data(CacheConfig, FileRecords, AllData) when CacheConfig#cache_mate.cache_type =:= mnesia ->
    to_mnesia:cache_data(CacheConfig, FileRecords, AllData).