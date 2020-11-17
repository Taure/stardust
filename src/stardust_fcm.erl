-module(stardust_fcm).

-export([start/1,
         start/2,
         stop/1,
         send/2,
         async_send/2]).

start(ServiceAccount) ->
    start(ServiceAccount, [{size, 5}, {max_overflow, 10}]).

start(#{<<"project_id">> := ProjectId} = ServiceAccount, PoolboyConfig) ->
    poolboy:start([{name, {local, binary_to_atom(ProjectId)}},
                   {worker_module, stardust_fcm_srv} | PoolboyConfig],
                  [ServiceAccount]).

stop(ProjectId) ->
    poolboy:stop(ProjectId).

-spec send(binary(), map()) -> ok | {error, integer(), binary()} | {error, term()}.
send(ProjectId, FCMobj) ->
    poolboy:transaction(binary_to_atom(ProjectId),
                        fun(Worker) ->
                            gen_server:call(Worker, {send, ProjectId, FCMobj})
                        end).

async_send(ProjectId, FCMobj) ->
    poolboy:transaction(binary_to_atom(ProjectId),
                        fun(Worker) ->
                            gen_server:cast(Worker, {send, ProjectId, FCMobj})
                        end).