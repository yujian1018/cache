%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%% Created : 26. 十一月 2015 下午5:46
%%%-------------------------------------------------------------------
-module(aof_mysql).

-define(no_cache_behaviour, 1).
-include("cache_pub.hrl").


-export([load_file/1]).

load_file(Config) ->
    case ?rpc_db_call(db_mysql, execute, [Config#cache_mate.mysql_pool, sql(Config)]) of
        [AllData, FieldData] ->
            Fun =
                fun(Line, Acc) ->
                    TabVO = check_field(Config, Line),
                    NewTabVO =
                        case Config#cache_mate.rewrite of
                            none -> TabVO;
                            FunRewrite ->
                                case catch FunRewrite(TabVO) of
                                    {'EXIT', E} -> erlang:throw({'EXIT', {Config, "rewrite err:", E}});
                                    VO -> VO
                                end
                        end,
                    NewTabVO2 = case Config#cache_mate.verify of
                                    none -> NewTabVO;
                                    FunVerify ->
                                        case catch FunVerify(NewTabVO) of
                                            true -> NewTabVO;
                                            _Catch -> erlang:throw({'EXIT', {Config, "verify err:", NewTabVO, _Catch}})
                                        end
                                end,
                    if
                        is_tuple(NewTabVO2) -> [NewTabVO2 | Acc];
                        is_list(NewTabVO2) -> NewTabVO2 ++ Acc;
                        true -> Acc
                    end
                end,
            Ret = lists:foldl(Fun, [], FieldData),
            {list_to_binary(erl_hash:md5(term_to_binary(AllData))), lists:reverse(Ret), AllData};
        _Other -> erlang:throw({'EXIT', {"read ", Config, "sql err:", _Other}})
    end.


sql(Config) ->
    Tab = atom_to_binary(Config#cache_mate.name, unicode),
    SelectBin =
        lists:foldl(fun(Field, SelectAcc) ->
            FieldBin = atom_to_binary(Field, unicode),
            if
                SelectAcc =:= <<>> -> <<"`", FieldBin/binary, "`">>;
                true -> <<SelectAcc/binary, ",`", FieldBin/binary, "`">>
            end
                    end,
            <<>>,
            Config#cache_mate.fields),
    <<"SELECT * FROM ", Tab/binary, ";SELECT ", SelectBin/binary, " FROM ", Tab/binary, ";">>.


check_field(Config, Line) ->
    TabFieldLen = length(Config#cache_mate.fields),
    LineLen = length(Line),
    if
        TabFieldLen =:= LineLen ->
            {_, Ret} =
                lists:foldl(
                    fun(I, {Index, Record}) ->
                        {Index + 1, setelement(Index, Record, I)}
                    end,
                    {2, Config#cache_mate.record},
                    Line),
            Ret;
        true ->
            erlang:throw({Config, "fields bad match:", Config})
    end.

