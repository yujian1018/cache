%%%-------------------------------------------------------------------
%%% @author yj
%%% @doc 读取文本中所有数据
%%%
%%% Created : 29. 九月 2018 下午3:47
%%%-------------------------------------------------------------------
-module(aof_file).

-define(no_cache_behaviour, 1).
-include("cache_pub.hrl").


-define(PAGE_SIZE, 10000).

-export([load_file/1]).

load_file(Config) ->
    case application:get_env(cache, dir) of
        {ok, Path} ->
            FileName =
                if
                    is_atom(Config#cache_mate.name) ->
                        filename:join([Path]) ++ "/" ++ atom_to_list(Config#cache_mate.name) ++ ".data";
                    is_list(Config#cache_mate.name) ->
                        Config#cache_mate.name;
                    true ->
                        ?ERROR("Config Err filename is  null")
                end,
            {ok, [Context]} = file:consult(FileName),
            Md5Context = erlang:md5_init(),
            {NewMd5Context, FieldRecords} = aof_mysql:cache_data(Config, Context, Md5Context, Context),
            cache_behaviour:cache_data(Config, erlang:md5_final(NewMd5Context), FieldRecords, Context);
        _ -> ?ERROR("cache no env dir")
    end.


