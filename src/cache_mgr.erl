%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 设计错误，小数据量可以接受，目前没有好想法
%%% Created : 08. 十二月 2015 上午11:26
%%%-------------------------------------------------------------------
-module(cache_mgr).

-behaviour(gen_server).

-define(no_cache_behaviour, 1).
-include("cache_pub.hrl").

-export([start_link/1, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% state = #{cache_mate => #cache_mate{}}.


start_link(CacheConfig) ->
    gen_server:start_link({local, CacheConfig#cache_mate.name}, ?MODULE, CacheConfig, []).


init(CacheConfig) ->
    ets:new(CacheConfig#cache_mate.name, [named_table, public, CacheConfig#cache_mate.table_type, {keypos, CacheConfig#cache_mate.key_pos}, {read_concurrency, true}]),
    
    if
        CacheConfig#cache_mate.record =:= none ->
            ok;
        true ->
            case catch load_file(CacheConfig) of
                {Md5, FileRecords, AllData} ->
                    cache_data(CacheConfig, Md5, FileRecords, AllData);
                _Cache ->
                    ?ERROR("load_file err:~p~n", [_Cache])
            end
    end,
    io:format("config table:~p load done~n", [CacheConfig#cache_mate.name]),
    {ok, #{config => CacheConfig}}.



handle_call({reset_md5, TabName, Md5}, _From, State) ->
    TabNameBin = list_to_binary(atom_to_list(TabName)),
    Reply =
        case ets:lookup(?cache_tab_md5, all_config) of
            [] ->
                ets:insert(?cache_tab_md5, {all_config, <<"{\"", TabNameBin/binary, "\":\"", Md5/binary, "\"}">>});
            [{all_config, Json}] ->
                {Obj} = jiffy:decode(Json),
                NewObj = lists:keystore(TabNameBin, 1, Obj, {TabNameBin, Md5}),
                NewJson = jiffy:encode({NewObj}),
                ets:insert(?cache_tab_md5, {all_config, NewJson})
        end,
    {reply, Reply, State};


handle_call({reset_cache, ConfigVO}, _From, State) ->
    Reply = case catch load_file(ConfigVO) of
                {'EXIT', Catch} ->
                    ?ERROR("reset_cache load_file err:~p~n", [Catch]),
                    {error, Catch};
                {NewMd5, NewFileRecords, AllData} ->
%% @doc 重新加载数据
                    case catch cache_data(ConfigVO, NewMd5, NewFileRecords, AllData) of
                        {'EXIT', Catch} ->
                            ?ERROR("reset_cache cache_data error:~p~n", [Catch]),
                            {error, Catch};
                        _ ->
                            ok
                    end
            end,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.


handle_cast(_Request, State) ->
    {noreply, State}.


handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, State) ->
    State.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


load_file(CacheConfig) when CacheConfig#cache_mate.type =:= mysql ->
    aof_mysql:load_file(CacheConfig).


cache_data(CacheConfig, Md5, FileRecords, AllData) ->
    All = cache_all_data(CacheConfig, FileRecords),
    DelIds =
        case All of
            [] -> [];
            [{_Name, Key, V} | _R] ->
                case ets:lookup(CacheConfig#cache_mate.name, Key) of
                    [] -> [];
                    [{_, _, V2}] -> V2 -- V
                end
        end,
    Group = cache_group_data(CacheConfig, FileRecords),
    
    ets:insert(CacheConfig#cache_mate.name, lists:flatten([All, Group, FileRecords])),
    ets:insert(CacheConfig#cache_mate.name, {CacheConfig#cache_mate.name, table_data, AllData}),
    gen_server:call(?cache_tab_md5, {reset_md5, CacheConfig#cache_mate.name, Md5}),
    case DelIds of
        [] -> ok;
        DelIds -> lists:map(fun(Id) -> ets:delete(CacheConfig#cache_mate.name, Id) end, DelIds)
    end.


cache_all_data(CacheConfig, FileRecords) ->
    if
        CacheConfig#cache_mate.all =:= [] ->
            [];
        true ->
            FunIndex =
                fun(Index) ->
                    ColumnAll = lists:map(fun(Record) -> element(Index, Record) end, FileRecords),
                    {CacheConfig#cache_mate.name, {'all', Index}, ColumnAll}
                end,
            lists:map(FunIndex, CacheConfig#cache_mate.all)
    end.

cache_group_data(Config, FileRecords) ->
    if
        Config#cache_mate.group =:= [] ->
            [];
        true ->
            FunIndex2 =
                fun(Index2) ->
                    FunFoldl =
                        fun(Record2, NewVO) ->
                            GroupTypeId = element(Index2, Record2),
                            KeyId2 = element(Config#cache_mate.key_pos, Record2),
                            case lists:keytake({'group', Index2, GroupTypeId}, 2, NewVO) of
                                false ->
                                    [{Config#cache_mate.name, {'group', Index2, GroupTypeId}, [KeyId2]} | NewVO];
                                {value, {_, _, KeyIds}, TupleList2} ->
                                    [{Config#cache_mate.name, {'group', Index2, GroupTypeId}, [KeyId2 | KeyIds]} | TupleList2]
                            end
                        end,
                    [{TabName, GroupK, lists:reverse(GroupV)} || {TabName, GroupK, GroupV} <- lists:foldl(FunFoldl, [], FileRecords)]
                end,
            lists:map(FunIndex2, Config#cache_mate.group)
    end.