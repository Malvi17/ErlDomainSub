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
    terminate/2, crea/1, get_timestamp/0, printLog/4, printLogFree/4]).

  %%Utilizza la funzione crea
  init([]) ->

    %%crea(1),
    {ok, []}.


  handle_event({free, FirstTime, Time3,Time4,Domain}, State) ->
    TimeRes = get_timestamp() - Time4,
    spawn(eventHandler,printLogFree,[FirstTime,Time3, TimeRes, Domain]),
    {ok, State};

  handle_event({active, FirstTime, Time3, Domain}, State) ->
    spawn(eventHandler,printLog,[FirstTime,Time3,Domain,active]),
    exit({active, State});

  handle_event({internalServerError, FirstTime, Time3, Domain}, State) ->
    spawn(eventHandler,printLog,[FirstTime,Time3,Domain,internalServerError]),
    exit({internalServerError, State});

  handle_event({inactive, FirstTime, Time3, Domain}, State) ->
    spawn(eventHandler,printLog,[FirstTime,Time3,Domain,inactive]),
    exit({inactive, State});

  handle_event({redemptionPeriod, FirstTime, Time3, Domain}, State) ->
    spawn(eventHandler,printLog,[FirstTime,Time3,Domain,redemptionPeriod]),
    {ok, State};

  handle_event({pendingDelete, FirstTime, Time3, Domain}, State) ->
    %%io:format("Arrivato~n"),
    spawn(eventHandler,printLog,[FirstTime,Time3,Domain,pendingDelete]),
    {ok, State};

  handle_event({limitExceeded, FirstTime, Time3, Domain}, State) ->
    %%io:format("Arrivato~n"),
    spawn(eventHandler,printLog,[FirstTime,Time3,Domain,limitExceeded]),
    exit({limitExceeded, State});

  handle_event(error, State) ->
    exit({error, State}).

  handle_call(_, State) ->
    {ok, ok, State}.

  handle_info(_, State) ->
    {ok, State}.

  code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

  terminate(_Reason, _State) ->
    ok.

  printLogFree(FirstTime, Time3, TimeRes, Domain) ->
    TimeStamp = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
    file:write_file("txt/"++Domain++".txt",[io_lib:format("[~p] status=free StartedAt: ~p Elapse: ~p ms ResponseTime = ~pms ~n",[TimeStamp,FirstTime,Time3,TimeRes])], [append]).

  printLog(FirstTime, Time3, Domain,active) ->
    TimeStamp = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
    file:write_file("txt/"++Domain++".txt",[io_lib:format("[~p] status=active StartedAt: ~p Elapse: ~p ms~n",[TimeStamp,FirstTime,Time3])], [append]);

  printLog(FirstTime, Time3, Domain,internalServerError) ->
    TimeStamp = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
    file:write_file("txt/"++Domain++".txt",[io_lib:format("[~p] status=internalServerError StartedAt: ~p Elapse: ~p ms~n",[TimeStamp,FirstTime,Time3])], [append]);

  printLog(FirstTime, Time3, Domain,inactive) ->
    TimeStamp = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
    file:write_file("txt/"++Domain++".txt",[io_lib:format("[~p] status=inactive StartedAt: ~p Elapse: ~p ms~n",[TimeStamp,FirstTime,Time3])], [append]);

  printLog(FirstTime, Time3, Domain,limitExceeded) ->
    TimeStamp = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
    file:write_file("txt/"++Domain++".txt",[io_lib:format("[~p] status=limitExceeded StartedAt: ~p Elapse: ~p ms~n",[TimeStamp,FirstTime,Time3])], [append]);

  printLog(FirstTime, Time3, Domain,pendingDelete) ->
    TimeStamp = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
    file:write_file("txt/"++Domain++".txt",[io_lib:format("[~p] status=pendingDelete StartedAt: ~p Elapse: ~p ms~n",[TimeStamp,FirstTime,Time3])], [append]);

  printLog(FirstTime, Time3, Domain,redemptionPeriod) ->
    TimeStamp = calendar:system_time_to_rfc3339(os:system_time(millisecond), [{unit, millisecond}]),
    file:write_file("txt/"++Domain++".txt",[io_lib:format("[~p] status=redemptionPeriod StartedAt: ~p Elapse: ~p ms~n",[TimeStamp,FirstTime,Time3])], [append]).




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