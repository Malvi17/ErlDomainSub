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
-export([start/2, send/8, create_packet/6, reverse_8bit/1, get_timestamp/0]).



start(Pid,Domain) ->
  %%
  PayloadTemplate = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><iris1:request xmlns:iris1=\"urn:ietf:params:xml:ns:iris1\"><iris1:searchSet><iris1:lookupEntity registryType=\"dchk1\" entityClass=\"domain-name\" entityName=\"test.fr\"/></iris1:searchSet></iris1:request>",
  PayloadTemplate1 = string:replace(PayloadTemplate,"test",Domain),
  TransactionID = <<0>>,
  MaxRes = 5000,
  MaxResponseLength = reverse_8bit(<<MaxRes:8/integer-unit:2>>),
  Authority = "fr",%% Prima lunghezza e poi fr
  AuthorityLength =  <<2>>,

  Host = {192,134,5,15},
  Port = 715,
  Packet = iolist_to_binary([0,0,TransactionID,MaxResponseLength,AuthorityLength,Authority,PayloadTemplate1]),
  %%{Socket,Packet, Host, Port, Domain}.
  %%{ok, Socket} = gen_udp:open(8000, [binary]),
  loop(Pid,Domain,Packet,Host,Port,8000).
  %%{ok,_Timer} = timer:apply_interval(5,domainStatusLookup,create_packet,[Pid,Domain,Socket,Packet,Host,Port]).
  %%spawn(domainStatusLookup,handle,[Socket,Host,Port,Pid,FirstTime,Time1,Domain]),
  %%create_packet(Pid,Domain,Socket,Packet,Host,Port).
  %%periodically:start({local,thing1},3000,fun() -> io:fwrite("thing1 says hi!\n") end)
  %%interval_loop:start({local,dasReq},5,fun(Pid,Domain,Socket,Packet,Host,Port)-> spawn(domainStatusLookup,create_packet,[Pid,Domain,Socket,Packet,Host,Port]) end).
  %%Pid1 = spawn(domainStatusLookup,create_packet,[Pid,Domain,Socket,Packet,Host,Port]),
  %%gen_udp:controlling_process(Socket, Pid1).

loop(Pid,Domain,Packet,Host,Port,N) ->
  {ok, Socket} = gen_udp:open(N, [binary]),
  %%io:format("~p~n~n",[Socket]),
  PidCreate = spawn(domainStatusLookup,create_packet,[Pid,Domain,Socket,Packet,Host,Port]),

  gen_udp:controlling_process(Socket, PidCreate),

  if N =:= 9000 ->
    timer:sleep(1000),
    loop(Pid,Domain,Packet,Host,Port,8000);
    true ->
      timer:sleep(1000),
      loop(Pid,Domain,Packet,Host,Port,N+1)
  end.

create_packet(Pid,Domain,Socket,Packet,Host,Port) ->
  %%USA REPLACE
  %%io:format("PARTO"),
  FirstTime = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
  Time1 = get_timestamp(),
  %%timer:sleep(2000),
  %%io:format("INVIO IL PACCHETTO~n~n"),
  %%spawn(domainStatusLookup,handle,[Socket,Host,Port,Pid,FirstTime,Time1,Domain]),
  send(Socket, Host, Port, Packet,Pid,FirstTime, Time1, Domain).
  %%spawn(domainStatusLookup,send,[Socket, Host, Port, Packet,Pid,FirstTime, Time1, Domain]).
  %%gen_udp:controlling_process(Socket, Pid1).
  %%spawn(domainStatusLookup,create_packet,[Pid,Domain,Socket,Packet,Host,Port]).
  %%timer:sleep(5),
  %%create_packet(Pid,Domain,Socket,Packet,Host,Port).




send(Socket, Host, Port, Packet,Pid,FirstTime,Time1,Domain) ->
      %%io:format(" SEND"),
      spawn(gen_udp,send,[Socket,Host,Port,Packet]),
      %%gen_udp:send(Socket, Host, Port, Packet),
      %%handle(Socket,Host,Port,Pid,FirstTime,Time1,Domain).
      %%handleB(Socket,Pid,FirstTime,Time1,Domain).
      %%PidCreate = spawn(domainStatusLookup,handle,[Socket,Host,Port,Pid,FirstTime,Time1,Domain]),
      %%PidCreate = spawn(domainStatusLookup,handleB,[Socket,Pid,FirstTime,Time1,Domain]),
      %%gen_udp:controlling_process(Socket,PidCreate).
      inet:setopts(Socket, [{active,false}]),
      {ok,{_Host,_Port,Bin}} = gen_udp:recv(Socket, 5000),
      %%io:format(" RICEVO"),
      Time2 = get_timestamp(),
      Time3 = Time2 - Time1,
      %%read_response(Bin,Pid,FirstTime,Time2, Time3,Fd).
      Res = bitstring_to_list(Bin)--[40,0,0],
      ResFinal = list_to_binary(Res),

      case string:find(ResFinal,"nameNotFound") of
        nomatch ->  ok;
        _ ->
          %%Time4 = get_timestamp(),
          %%io:format("FACCIO NOTIFY~n~n"),
          gen_event:notify(Pid,{free, FirstTime, Time3, Time2,Domain})
        %%gen_udp:close(Socket)
      end,

      case string:find(ResFinal,"active") of
        nomatch -> ok;
        _ -> %%io:format(" Notify"),
          gen_event:notify(Pid,{active, FirstTime, Time3, Domain})
        %%gen_udp:close(Socket)
      end,

      case string:find(ResFinal,"inactive") of
        nomatch -> ok;
        _ -> %%io:format("ATTIVO~n~n")
          gen_event:notify(Pid,{inactive, FirstTime, Time3, Domain})
      end,

      case string:find(ResFinal,"redemptionPeriod") of
        nomatch -> ok;
        _ -> %%io:format("ATTIVO~n~n")
          gen_event:notify(Pid,{redemptionPeriod, FirstTime, Time3})
      end,

      case string:find(ResFinal,"delete") of
        nomatch -> ok;
        _ -> %%io:format("ATTIVO~n~n")
          gen_event:notify(Pid,{delete, FirstTime, Time3})
      end,

      case string:find(ResFinal,"delete") of
        nomatch -> ok;
        _ -> %%io:format("ATTIVO~n~n")
          gen_event:notify(Pid,{libero, FirstTime, Time3})
      end.

reverse_8bit(<<X:8,Rest/bits>>) ->
  <<(reverse_8bit(Rest))/bits,X:8>>;
reverse_8bit(<<>>) ->
  <<>>.

get_timestamp() ->
  {Mega, Sec, Micro} = os:timestamp(),
  (Mega*1000000 + Sec)*1000 + Micro/1000.















%% Funzione che si connette al socket creato dal dominio e fa partire handle
%%start(Pid) ->
  %%{ok, Socket} = gen_udp:open(8790).
  %%gen_udp:send(Socket, {127,0,0,1}, 8789, "hey there!").
  %%{ok, Socket} = gen_tcp:connect({127,0,0,1}, 8088, [binary, {active, true}]),
  %%handle(Socket,Pid),
  %%gen_tcp:close(Socket).

%% Funzione che se riceve il messaggio giusto da parte del dominio manda una sync_notify.
%% Utilizza una notify sincrona per poter ottenere un risultato approssimativamente più corretto dato che
%% il timer si blocca solo quando tutti gli handler hanno gestito l'evento.
%%handle(Socket,Pid) ->
  %%receive
    %%{tcp,Socket,<<"Dominio Libero">>} ->
      %%io:format("Mi sottoscrivo al dominio libero~n")
      %%{Time,_} =timer:tc(fun gen_event:sync_notify/2,[Pid,{libero}]),
      %%io:format("Ci ha messo ~.5f ms~n",[Time/1000])
  %%end.

