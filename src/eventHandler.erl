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
  terminate/2, crea/1, get_timestamp/0]).

%%Utilizza la funzione crea
init([]) ->

  %%crea(1),
  {ok, []}.

%%Gestisce l'evento libero e pubblica sul topic domain il messaggio "parti"
handle_event({free, FirstTime, Time3, Time2,Domain}, State) ->
  %%io:format("PACCHETTO ARRIVATO~n~n"),
  Time5 = get_timestamp(),
  ResTime = Time5-Time2,
  %%Ts = os:timestamp(),
  %%{{Year,Month,Day},{_Hour,_Minute,_Second}} = calendar:now_to_universal_time(Ts),
  %%{ok, S} = file:open("/txt/malvi.txt", [append]),
  %%++integer_to_list(Year)++"_"++integer_to_list(Month)++"_"++integer_to_list(Day)
  io:format(Domain, "STATUS=FREE~nQuery sent: ~p~nElapsed Time: ~p ms~nResponse Time: ~p ms~n~n~n",[FirstTime,Time3,ResTime]),
  %%file:close(IoDevice),
  %%ebus:pub(domain,"parti"),
  exit({free, State});

handle_event({active, FirstTime, Time3, Domain}, State) ->
  %%io:format("Arrivato~n"),
  TimeStamp = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
  %%Data = "["++TimeStamp++"]"++" StartedAt:"++FirstTime++" status=active elapse:"++ Time3,
  %%{ok, IoDevice}=file:open("txt/"++Domain++".txt", [append]),
  %%{ok, Fd1}=file:open("txt/afnic.txt", [append]),
  %%io:format(Fd1, "[~p] status=active StartedAt: ~p Elapse: ~p ms~n",[TimeStamp,FirstTime,Time3]),
  %%io:format(Fd, "STATUS=INACTIVE~nQuery sent: ~p~nElapsed Time: ~p ms~n~n~n",[FirstTime,Time3]),
  %%file:close(IoDevice),
  file:write_file("txt/"++Domain++".txt",[io_lib:format("[~p] status=active StartedAt: ~p Elapse: ~p ms~n",[TimeStamp,FirstTime,Time3])], [append]),
  {ok, State};

handle_event({inactive, FirstTime, Time3, Domain}, State) ->
  Ts = os:timestamp(),
  {{Year,Month,Day},{_Hour,_Minute,_Second}} = calendar:now_to_universal_time(Ts),
  {ok, IoDevice}=file:open("txt/"++Domain++"_"++integer_to_list(Year)++"_"++integer_to_list(Month)++"_"++integer_to_list(Day)++".txt", [append]),
  io:format(IoDevice, "STATUS=INACTIVE~nQuery sent: ~p~nElapsed Time: ~p ms~n~n~n",[FirstTime,Time3]),
  file:close(IoDevice),
  {ok, State};

handle_event({redemptionPeriod, FirstTime, Time3, Domain}, State) ->
  Ts = os:timestamp(),
  {{Year,Month,Day},{_Hour,_Minute,_Second}} = calendar:now_to_universal_time(Ts),
  {ok, IoDevice}=file:open("txt/"++Domain++"_"++integer_to_list(Year)++"_"++integer_to_list(Month)++"_"++integer_to_list(Day)++".txt", [append]),
  io:format(IoDevice, "STATUS=REDEMPTION PERIOD~nQuery sent: ~p~nElapsed Time: ~p ms~n~n~n",[FirstTime,Time3]),
  file:close(IoDevice),
  {ok, State};

handle_event({delete, FirstTime, Time3, Domain}, State) ->
  Ts = os:timestamp(),
  {{Year,Month,Day},{_Hour,_Minute,_Second}} = calendar:now_to_universal_time(Ts),
  {ok, IoDevice}=file:open("txt/"++Domain++"_"++integer_to_list(Year)++"_"++integer_to_list(Month)++"_"++integer_to_list(Day)++".txt", [append]),
  io:format(IoDevice, "STATUS=DELETE~nQuery sent: ~p~nElapsed Time: ~p ms~n~n~n",[FirstTime,Time3]),
  file:close(IoDevice),
  {ok, State};

handle_event(_, State) ->
  {ok2, State}.

handle_call(_, State) ->
  {ok, ok, State}.

handle_info(_, State) ->
  {ok, State}.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

terminate(_Reason, _State) ->
  ok.

%%Funzione che crea 4 processi, generati come handler di erlbus attraverso spawn_handler.
%%Attraverso sub invece si sottoscrive al topic domain
crea(N) ->
  case N of
    0 -> io:format("Tutti i processi sono stati creati~n");
    _->
      H = ebus_proc:spawn_handler(fun provaSub:handle_msg/2,[self()]),
      ebus:sub(H,domain),
      io:format("Processo ~p creato e subbato al topic domain~n",[H]),
      crea(N-1)

  end.

get_timestamp() ->
  {Mega, Sec, Micro} = os:timestamp(),
  (Mega*1000000 + Sec)*1000 + Micro/1000.