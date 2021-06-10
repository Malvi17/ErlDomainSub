%%%-------------------------------------------------------------------
%%% @author malvi
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. Jun 2021 19:11
%%%-------------------------------------------------------------------
-module(domainStatusLookup).
-author("malvi").

%% API
-export([start/1]).

start(Pid) ->

  {ok, Socket} = gen_tcp:connect({127,0,0,1}, 8088, [binary, {active, true}]),
  handle(Socket,Pid),
  gen_tcp:close(Socket).

handle(Socket,Pid) ->
  receive
    {tcp,Socket,<<"Dominio Libero">>} ->
      %%io:format("Mi sottoscrivo al dominio libero~n")
      {Time,_} =timer:tc(fun gen_event:sync_notify/2,[Pid,{libero}]),%%gen_event:notify(Pid, {libero})
      io:format("Ci ha messo ~.5f ms~n",[Time/1000])
  end.

