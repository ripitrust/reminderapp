-module(evserv).
-compile(export_all).


loop(State) ->

    receive
        {Pid, MsgRef, {subscribe, Client}} ->

        Ref = erlang:monitor(process, Client)
        NewClient = orddict:store(Ref, Client, S#state.clients),
        Pid ! {MsgRef, ok},
        loop(S#state{clients=NewClient});

        {Pid, MsgRef, {add, Name, Description, TimeOut}} ->

        case valid_datetime(TimeOut) of

            true ->
                EventPid = event:start_link(Name, TimeOut),
                NewEvents = orddict:store(Name, 
                                          #event{name=Name,
                                                 description=Description,
                                                 pid=EventPid,
                                                 timeout=TimeOut},
                                          S#state.events),
                Pid ! {MsgRef, ok},
                loop(S#state{events=NewEvents});

            false ->
                Pid ! {MsgRef, {error, bad_timeout}},
                loop(S)

        end;



        {Pid, MsgRef, {cancel, Name}} ->

            Events = case orddict:find(Name, S#state.events) of
                         { ok, E } ->
                            events:cancel(E#event.pid),
                            orddict:erase(Name, S#state.events);
                        error ->
                            S#state.events

                        end,
            Pid ! { MsgRef, ok },

            loop(S#state{events=Events});

        {done, Name} ->
        ...

        shutdown ->
        ...


valid_datetime({Date, Time}) ->
    try
        calendar:valid_date(Date) andalso valid_time(Time)

    catch
        error:function_clause -> 
        false
    end;

valid_datetime(_) ->
false.


valid_time({H, M, S}) -> valid_time(H, M, S).
valid_time(H, M, S) when H >= 0, H < 24,
                         M >= 0, M < 60,
                         S >= 0, S < 60 -> true;

valid_time(_,_,_) -> false.
