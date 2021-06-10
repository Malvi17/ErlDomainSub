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
%% Funzione che si connette al socket creato dal dominio e fa partire handle
start(Pid) ->

  {ok, Socket} = gen_tcp:connect({127,0,0,1}, 8088, [binary, {active, true}]),
  handle(Socket,Pid),
  gen_tcp:close(Socket).

%% Funzione che se riceve il messaggio giusto da parte del dominio manda una sync_notify.
%% Utilizza una notify sincrona per poter ottenere un risultato approssimativamente più corretto dato che
%% il timer si blocca solo quando tutti gli handler hanno gestito l'evento.
handle(Socket,Pid) ->
  receive
    {tcp,Socket,<<"Dominio Libero">>} ->
      %%io:format("Mi sottoscrivo al dominio libero~n")
      {Time,_} =timer:tc(fun gen_event:sync_notify/2,[Pid,{libero}]),
      io:format("Ci ha messo ~.5f ms~n",[Time/1000])
  end.

