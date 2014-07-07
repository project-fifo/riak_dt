%% -------------------------------------------------------------------
%%
%% riak_dt_map: OR-Set schema based multi CRDT containerm, using Paulo's design
%%
%% Copyright (c) 2007-2013 Basho Technologies, Inc.  All Rights Reserved.
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

-module(riak_dt_paulo_map).

-ifdef(EQC).
-include_lib("eqc/include/eqc.hrl").
-endif.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-compile(export_all).

new() ->
    {riak_dt_vclock:new(), orddict:new()}.

value({_Clock, Fields}) ->
    orddict:fold(fun({Name, Type}, CRDT, Acc) ->
                                [{Name, Type:value(CRDT)} | Acc] end,
                 [],
                 Fields).

get({_Name, Type}=Field, Fields, Clock) ->
    case orddict:find(Field, Fields) of
        {ok, CRDT} ->
            Type:parent_clock(Clock, CRDT);
        error ->
            Type:parent_clock(Clock, Type:new())
    end.

merge({Clock1, Fields1}, {Clock2, Fields2}) ->
    Clock = riak_dt_vclock:merge([Clock1, Clock2]),
    {Merged0, RHSUnique} = orddict:fold(fun({_Name, Type}=Field, CRDT, Acc) ->
                                                LHS = get(Field, Fields1),
                                                RHS = get(Field, Fields2),
                                                Merged = Type:merge(LHS, RHS),
                                                {orddict:store(Field, Merged),
                                                 orddict:erase(Field, Fields2)}
                                        end,
                                        orddict:new(),
                                        Fields1),
    Merged = orddict:fold(fun({_Name, Type}=Field, 



