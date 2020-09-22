%%%-------------------------------------------------------------------
%% @doc stardust public API
%% @end
%%%-------------------------------------------------------------------

-module(stardust_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    stardust_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
