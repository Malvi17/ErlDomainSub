  %%%-------------------------------------------------------------------
  %%% @author Gianluca Malvicini
  %%% @copyright (C) 2021, <COMPANY>
  %%% @doc
  %%%
  %%% @end
  %%% Created : 06. Jun 2021 19:11
  %%%-------------------------------------------------------------------
  -module(domainStatusLookup).
  -author("Gianluca Malvicini").

  %% API
  -export([start/2, sendPacket/6, reverse_8bit/1, get_timestamp/0,handlePacket/5,loop/6]).



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
    test(Pid,Domain,Packet,Host,Port,8000).


  test(Pid,Domain,Packet,Host,Port,N)->
    {{_Year, _Month, _Day}, {_Hour, Minute, Second}} = calendar:now_to_datetime(os:timestamp()),
    %%io:format("~p,~p~n",[Minute,Second]),
    if Minute =:= 32 andalso Second =:= 10 ->
      loop(Pid,Domain,Packet,Host,Port,N);

      true -> test(Pid,Domain,Packet,Host,Port,N)
    end.

  loop(Pid,Domain,Packet,Host,Port,N) ->
    {X, Socket} = gen_udp:open(N, [binary]),
    %%io:format("~p,~p~n",[X,Socket]),
    case X of
      ok->

        spawn(domainStatusLookup,sendPacket,[Pid,Domain,Socket,Packet,Host,Port]),

        if N =:= 9000 ->
          timer:sleep(520),
          loop(Pid,Domain,Packet,Host,Port,8000);
          true ->
            timer:sleep(520),
            loop(Pid,Domain,Packet,Host,Port,N+1)
        end;
      _ -> io:format("~p,~p~n",[X,Socket])

    end.


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
        spawn(domainStatusLookup,handlePacket,[Bin,FirstTime,Time3,Domain,Pid]);
      _ -> gen_udp:close(Socket)
    end.


  handlePacket(Bin,FirstTime,Time3,Domain,Pid) ->
    Res = bitstring_to_list(Bin)--[40,0,0],
    ResFinal = list_to_binary(Res),

    case string:find(ResFinal,"nameNotFound") of

      nomatch ->
         case string:find(ResFinal,"genericCode") of
           nomatch ->
              case string:find(ResFinal,"inactive") of
                nomatch ->
                   case string:find(ResFinal,"active") of
                     nomatch ->
                        case string:find(ResFinal,"redemptionPeriod") of
                          nomatch ->
                             case string:find(ResFinal,"delete") of
                               nomatch ->
                                  case string:find(ResFinal,"limitExceeded") of
                                    nomatch -> gen_event:notify(Pid,{error});
                                    _ ->
                                      gen_event:notify(Pid,{limitExceeded, FirstTime, Time3, Domain})
                                  end;
                               _ ->
                                 gen_event:notify(Pid,{pendingDelete, FirstTime, Time3, Domain})
                             end;
                          _ ->
                            gen_event:notify(Pid,{redemptionPeriod, FirstTime, Time3, Domain})
                        end;
                     _ ->
                       gen_event:notify(Pid,{active, FirstTime, Time3, Domain})
                   end;
                _ -> case string:find(ResFinal,"delete") of
                       nomatch -> gen_event:notify(Pid,{inactive, FirstTime, Time3, Domain});
                       _ ->
                      gen_event:notify(Pid,{pendingDelete, FirstTime, Time3, Domain})
                     end
              end;
           _ ->
             gen_event:notify(Pid,{internalServerError, FirstTime, Time3, Domain})
         end;
      _ ->
        TimeRes = get_timestamp(),
        gen_event:notify(Pid,{free, FirstTime, Time3,TimeRes,Domain})
    end.



  reverse_8bit(<<X:8,Rest/bits>>) ->
    <<(reverse_8bit(Rest))/bits,X:8>>;
  reverse_8bit(<<>>) ->
    <<>>.

  get_timestamp() ->
    {Mega, Sec, Micro} = os:timestamp(),
    (Mega*1000000 + Sec)*1000 + Micro/1000.

