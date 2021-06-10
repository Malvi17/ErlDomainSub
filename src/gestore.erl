%%%-------------------------------------------------------------------
%%% @author malvi
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. Jun 2021 19:14
%%%-------------------------------------------------------------------
-module(gestore).
-author("malvi").

%% API
-export([start_link/0]).

start_link() ->
  {ok, Pid} = gen_event:start_link(),
  gen_event:add_handler(Pid, eventHandler, []),
  {ok,Pid}.
