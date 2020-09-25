-module(stardust_apns).

-export([start/3,
         start/4,
         send/5,
         stop/1]).

start(KeyId, TeamId, P8) ->
    poolboy:start([{name, {local, binary_to_atom(KeyId)}},
                   {worker_module, stardust_apns_srv},
                   {size, 5}, 
                   {max_overflow, 10}], 
                   [{key, KeyId},
                    {team, TeamId},
                    {p8, P8}]).

start(KeyId, TeamId, P8, PoolboyConfig) ->
    poolboy:start([{name, {local, binary_to_atom(KeyId)}},
                   {worker_module, stardust_apns_srv} | PoolboyConfig],
                  [{key, KeyId},
                   {team, TeamId},
                   {p8, P8}]).

send(KeyId, BundleId, Message, DeviceToken, ApnsType) ->
    poolboy:transaction(binary_to_atom(KeyId),
                        fun(Worker) ->
                            gen_server:call(Worker, {send, BundleId, Message, DeviceToken, ApnsType})
                        end).

stop(KeyId) ->
    poolboy:stop(KeyId).