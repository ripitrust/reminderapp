-module(hotload).
-export([server/1, upgrade/1]).


server(State) ->
    receive
        update ->
            NewState = ?MODULE:upgrade(State),

            ?MODULE:server(NewState);

        SomeMsg ->
            server(State)

    end.


upgrade(OldState) ->

%%