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
    cache_data/3
]).

init(_CacheConfig) ->
%%    ?mnesia_new(CacheConfig#cache_mate.name, CacheConfig#cache_mate.table_type).
    ok.

cache_data(_CacheConfig, FileRecords, _AllData) ->
    [mnesia:dirty_write(Record) || Record <- FileRecords].