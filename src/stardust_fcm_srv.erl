-module(stardust_fcm_srv).
-behaviour(gen_server).
-behaviour(poolboy_worker).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
		 handle_cast/2,
		 handle_info/2,
	     terminate/2, 
		 code_change/3, 
		 format_status/2]).

-export([send/2]).

-define(TTL, 1800000).

-include("stardust.hrl").

-record(state, {service_account,
                access_token}).

%%%===================================================================
%%% API
%%%===================================================================

-spec send(binary(), map()) -> list().
send(ProjectId, FCMobj) ->
	gen_server:call(?MODULE, {send, {ProjectId, FCMobj}}).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link(term()) -> {ok, Pid :: pid()} |
		      {error, Error :: {already_started, pid()}} |
		      {error, Error :: term()} |
		      ignore.
start_link(Args) ->
	gen_server:start_link(?MODULE, Args, []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
			      {ok, State :: term(), Timeout :: timeout()} |
			      {ok, State :: term(), hibernate} |
			      {stop, Reason :: term()} |
			      ignore.
init([ServiceAccount]) ->
    process_flag(trap_exit, true),
    gen_server:cast(?MODULE, {start, ServiceAccount}),
    {ok, #state{service_account = ServiceAccount}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
			 {reply, Reply :: term(), NewState :: term()} |
			 {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
			 {reply, Reply :: term(), NewState :: term(), hibernate} |
			 {noreply, NewState :: term()} |
			 {noreply, NewState :: term(), Timeout :: timeout()} |
			 {noreply, NewState :: term(), hibernate} |
			 {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
			 {stop, Reason :: term(), NewState :: term()}.
handle_call({send, ProjectId, FCMobj}, _From, State) ->
    Reply = firebase_message:send(ProjectId, State#state.access_token, FCMobj),
	{reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_cast(Request :: term(), State :: term()) ->
			 {noreply, NewState :: term()} |
			 {noreply, NewState :: term(), Timeout :: timeout()} |
			 {noreply, NewState :: term(), hibernate} |
			 {stop, Reason :: term(), NewState :: term()}.
handle_cast({start, ServiceAccount}, State) ->
    case firebase_oauth2:service_account_fcm(ServiceAccount) of
        #{status := {200, _}, body := Body} ->
            #{<<"access_token">> := Jwt} = json:decode(Body, [maps]),
            timer:apply_after(?TTL, gen_server, cast, [{start, ServiceAccount}]),
            {noreply, State#state{service_account = ServiceAccount, access_token = Jwt}};
        Reason ->
            ?WARNING("Failed to auth FCM: ~p", [Reason]),
            {noreply, State}
    end;
handle_cast({send, ProjectId, FCMobj}, State) ->
	firebase_message:send(ProjectId, State#state.access_token, FCMobj),
	{noreply, State};
handle_cast(Request, State) ->
    ?WARNING("UNEXPECTED CAST: ~p State: ~p", [Request, State]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
			 {noreply, NewState :: term()} |
			 {noreply, NewState :: term(), Timeout :: timeout()} |
			 {noreply, NewState :: term(), hibernate} |
			 {stop, Reason :: normal | term(), NewState :: term()}.
handle_info(Info, State) ->
    ?WARNING("UNEXPECTED: ~p State: ~p", [Info, State]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
				      {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
