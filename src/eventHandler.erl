%%%-------------------------------------------------------------------
%%% @author malvi
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. Jun 2021 19:12
%%%-------------------------------------------------------------------
-module(eventHandler).
-author("malvi").
-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, handle_info/2, code_change/3,
  terminate/2, crea/1]).

init([]) ->
  crea(4),
  {ok, []}.

handle_event({libero}, State) ->
  ebus:pub(domain,"parti"),
  {ok, State};

handle_event(_, State) ->
  {ok, State}.

handle_call(_, State) ->
  {ok, ok, State}.

handle_info(_, State) ->
  {ok, State}.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

terminate(_Reason, _State) ->
  ok.

crea(N) ->
  case N of
    0 -> io:format("Tutti i processi sono stati creati~n");
    _->
      H = ebus_proc:spawn_handler(fun provaSub:handle_msg/2,[self()]),
      ebus:sub(H,domain),
      io:format("Processo ~p creato e subbato al topic domain~n",[H]),
      crea(N-1)

  end.

