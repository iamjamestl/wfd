%%%
%%% wfd_app.erl
%%% Copyright (C) 2012 James Lee
%%% 
%%% This program is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU General Public License as published by
%%% the Free Software Foundation, either version 3 of the License, or
%%% (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%%

-module(wfd_app).
-behaviour(application).
-export([start/0, stop/0, install/1, uninstall/1]).
-export([start/2, stop/1]).

-include("wfd.hrl").

-ifdef(TEST).
-export([test_setup/0, test_cleanup/1]).

test_setup() ->
    error_logger:tty(false),
    application:set_env(mnesia, dir, "mnesia"),
    install([node()]),
    start().

test_cleanup(_R) ->
    stop(),
    uninstall([node()]).
-endif.

%%
%% API
%%
start() ->
    application:start(mnesia),
    application:start(nprocreg),
    application:start(inets),
    application:start(bcrypt),
    application:start(wfd).

stop() ->
    application:start(wfd),
    application:start(bcrypt),
    application:start(inets),
    application:start(nprocreg),
    application:start(mnesia).

install(Nodes) ->
    % See: http://learnyousomeerlang.com/mnesia#creating-tables-for-real
    rpc:multicall(Nodes, application, stop, [mnesia]),
    mnesia:create_schema(Nodes),
    rpc:multicall(Nodes, application, start, [mnesia]),
    mnesia:create_table(wfd_user, [{disc_copies, Nodes}, {attributes, record_info(fields, wfd_user)}]),
    mnesia:create_table(wfd_dish, [{type, bag}, {disc_copies, Nodes}, {attributes, record_info(fields, wfd_dish)}, {index, [user]}]),
    mnesia:create_table(wfd_dish_photo, [{frag_properties, [{node_pool, Nodes}, {n_fragments, 1}, {n_disc_only_copies, length(Nodes)}]}, {attributes, record_info(fields, wfd_dish_photo)}]),
    mnesia:create_table(wfd_ingredient, [{type, bag}, {disc_copies, Nodes}, {attributes, record_info(fields, wfd_ingredient)}, {index, [user]}]),
    ok.

uninstall(Nodes) ->
    rpc:multicall(Nodes, application, stop, [mnesia]),
    mnesia:delete_schema(Nodes),
    ok.

%%
%% Callbacks
%%
start(_StartType, _StartArgs) ->
    wfd_sup:start_link().

stop(_State) ->
    ok.
