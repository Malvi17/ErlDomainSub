%%%-------------------------------------------------------------------
%%% @author malvi
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. Jun 2021 19:16
%%%-------------------------------------------------------------------
-module(dominio).
-author("malvi").

%% API
-export([server/0]).

%%Funzione che genera un socket sulla porta 8080 e rimane in attesa per accettare una connessione da parte di domainStatusLookup.
%%Passati poi 10 secondi se la connessione è avvenuta invia al Socket generato il messaggio
server() ->
  {ok, LSocket} = gen_tcp:listen(8088, [binary, {active, true}]),
  {ok, Socket} = gen_tcp:accept(LSocket),
  timer:sleep(10000),
  gen_tcp: send(Socket,"Dominio Libero"),
  ok = gen_tcp:close(Socket),
  ok = gen_tcp:close(LSocket).
%%Bin.
