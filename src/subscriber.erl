%%%-------------------------------------------------------------------
%%% @author malvi
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. Jun 2021 19:13
%%%-------------------------------------------------------------------
-module(subscriber).
-author("malvi").

%% API
-export([handle_msg/2]).

handle_msg(Msg, Context) ->
  io:format("[Pid: ~p][Msg: ~p][Ctx: ~p]~n",
    [self(), Msg, Context]).
