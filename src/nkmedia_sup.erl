%% -------------------------------------------------------------------
%%
%% Copyright (c) 2016 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @private NkMEDIA  main supervisor
-module(nkmedia_sup).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').
-behaviour(supervisor).

-export([start_child/2, start_janus_engine/1]).
-export([init/1, start_link/0]).

-include("nkmedia.hrl").


%% @private
start_child(Module, #{name:=Name}=Config) ->
    ChildId = {Module, Name},
    Spec = {
        ChildId,
        {Module, start_link, [Config]},
        transient,
        5000,
        worker,
        [Module]
    },
    case supervisor:start_child(?MODULE, Spec) of
        {ok, Pid} -> 
            {ok, Pid};
        {error, already_present} ->
            ok = supervisor:delete_child(?MODULE, ChildId),
            start_child(Module, Config);
        {error, {already_started, Pid}} -> 
            {ok, Pid};
        {error, Error} -> 
            {error, Error}
    end.




start_janus_engine(#{name:=Name}=Config) ->
    ChildId = {nkmedia_janus_engine, Name},
    Spec = {
        ChildId,
        {nkmedia_janus_engine, start_link, [Config]},
        transient,
        5000,
        worker,
        [nkmedia_janus_engine]
    },
    case supervisor:start_child(?MODULE, Spec) of
        {ok, Pid} -> 
            {ok, Pid};
        {error, already_present} ->
            ok = supervisor:delete_child(?MODULE, ChildId),
            start_janus_engine(Config);
        {error, {already_started, Pid}} -> 
            {ok, Pid};
        {error, Error} -> 
            {error, Error}
    end.



% stop_fs(#{index:=Index}) ->
%     ChildId = {nkmedia_fs_server, Index},
%     case supervisor:terminate_child(?MODULE, ChildId) of
%         ok -> ok = supervisor:delete_child(?MODULE, ChildId);
%         {error, Error} -> {error, Error}
%     end.


%% @private
-spec start_link() ->
    {ok, pid()}.

start_link() ->
    Childs = case nkmedia_app:get(no_docker) of
        false ->
            [
                % {
                %     docker,
                %     {nkmedia_docker, start_link, []},
                %     permanent,
                %     5000,
                %     worker,
                %     [nkmedia_docker]
                % }
            ];
        true ->
            []
    end,
    supervisor:start_link({local, ?MODULE}, ?MODULE, {{one_for_one, 10, 60}, Childs}).


%% @private
init(ChildSpecs) ->
    {ok, ChildSpecs}.


