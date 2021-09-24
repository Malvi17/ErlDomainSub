%%%-------------------------------------------------------------------
%%% @author malvi
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. Jun 2021 19:11
%%%-------------------------------------------------------------------
-module(domainStatusLookup2).
-author("malvi").

%% API
-export([start/2, sendPacket/6, reverse_8bit/1, get_timestamp/0,startSend/6,handlePacket/6]).



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
  %%ListSocket = socketList(8000,[]),
  %%startSend(Pid,Domain,Packet,Host,Port,ListSocket).
  %%loop(Pid,Domain,Packet,Host,Port,ListSocket).
  loop(Pid,Domain,Packet,Host,Port,8000).



%%socketList(N,List)->
  %%if N =:= 9000->
  %%{ok, Socket} = gen_udp:open(N, [binary]),
  %%[Socket|List];
  %%true ->
    %%{ok, Socket} = gen_udp:open(N, [binary]),
    %%socketList(N+1,[Socket|List])
  %%end.

%%loop(Pid,Domain,Packet,Host,Port,ListSocket)->
  %%startSend(Pid,Domain,Packet,Host,Port,ListSocket),
  %%loop(Pid,Domain,Packet,Host,Port,ListSocket).

loop(Pid,Domain,Packet,Host,Port,N) ->
  {X, Socket} = gen_udp:open(N, [binary]),
  %%io:format("~p,~p~n",[X,Socket]),
  case X of
    ok->

      spawn(domainStatusLookup2,sendPacket,[Pid,Domain,Socket,Packet,Host,Port]),

      %%gen_udp:controlling_process(Socket, PidCreate),

      if N =:= 9000 ->
        timer:sleep(1000),
        loop(Pid,Domain,Packet,Host,Port,8000);
        true ->
          timer:sleep(1000),
          loop(Pid,Domain,Packet,Host,Port,N+1)
      end;
    _ -> io:format("~p,~p~n",[X,Socket])

  end.

startSend(_Pid,_Domain,_Packet,_Host,_Port,[]) ->
  ok;

startSend(Pid,Domain,Packet,Host,Port,[Socket|List]) ->
  spawn(domainStatusLookup2,sendPacket,[Pid,Domain,Socket,Packet,Host,Port]),
  timer:sleep(5),
  startSend(Pid,Domain,Packet,Host,Port,List).

sendPacket(Pid,Domain,Socket,Packet,Host,Port) ->
  %%io:format(" SEND"),
  FirstTime = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
  Time1 = get_timestamp(),
  spawn(gen_udp,send,[Socket,Host,Port,Packet]),

  inet:setopts(Socket, [{active,false}]),
  %%{ok,{_Host,_Port,Bin}} =
  case gen_udp:recv(Socket, 5000,500) of
    {ok,{_Host,_Port,Bin}} ->
        gen_udp:close(Socket),
        Time2 = get_timestamp(),
        Time3 = Time2 - Time1,
        spawn(domainStatusLookup2,handlePacket,[Bin,FirstTime,Time3,Time2,Domain,Pid]);
    _ -> gen_udp:close(Socket)
  end.


handlePacket(Bin,FirstTime,Time3,Time2,Domain,Pid) ->
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
    _ -> io:format("INACTIVE~n~n")

  end,

  case string:find(ResFinal,"limitExceeded") of
    nomatch -> ok;
    _ -> io:format("limitExceeded~n~n")

  end,

  case string:find(ResFinal,"delete") of
    nomatch -> ok;
    _ -> io:format("delete~n~n")
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

