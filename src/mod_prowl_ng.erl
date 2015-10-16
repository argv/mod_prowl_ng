%%%----------------------------------------------------------------------

%%% File    : mod_prowl_ng.erl
%%% Author  : argv - Merdal Kaymaz
%%% Purpose : Push offline events to Prowl
%%% API     : http://www.prowlapp.com/api.php
%%% URL     : https://github.com/argv/mod_prowl_ng
%%% Created : 10 Oct 2015 by argv

%%%----------------------------------------------------------------------

%%% Debug
%%-define(ejabberd_debug, true).

-module(mod_prowl_ng).
-author('argv - Merdal Kaymaz').

-behaviour(gen_mod).

%% External exports
-export([start/2,
 init/2,
 stop/1,
 type/1,
 destination/1,
 source/1,
 event/1,
 key/1,
 match/3,
 uri/3,
 push/3]).

-include("ejabberd.hrl").
-include("logger.hrl").
-include("jlib.hrl").

-define(PROCNAME, ?MODULE).

%% API
start(Host, Opts) ->
  ?INFO_MSG("module ~p", [Host]),
  register(?PROCNAME, spawn(?MODULE, init, [Host, Opts])),
  ok.

init(Host, _Opts) ->
  ?INFO_MSG("module ~p", [_Opts]),
  inets:start(),
  ssl:start(),
  ejabberd_hooks:add(offline_message_hook, Host,
    ?MODULE, match, 10),
  ok.

stop(Host) ->
  ?INFO_MSG("module ~p", [Host]),
  ejabberd_hooks:delete(offline_message_hook, Host,
    ?MODULE, match, 10),
  ok.

%% Data
type(Packet) ->
  xml:get_tag_attr_s(<<"type">>, Packet).

destination(To) ->
  [To#jid.luser, "@", To#jid.lserver].

source(From) ->
  [From#jid.luser, "@", From#jid.lserver].

event(Packet) ->
  xml:get_path_s(Packet, [{elem, <<"body">>}, cdata]).

data(Source, Entry) ->
  case Entry of
    "Type"        -> xml:get_tag_attr_s(<<"type">>, Source);
    "Destination" -> [Source#jid.luser, "@", Source#jid.lserver];
    "Source"      -> [Source#jid.luser, "@", Source#jid.lserver];
    "Event"       -> xml:get_path_s(Source, [{elem, <<"body">>}, cdata]);
    _             -> "No value" 
  end.

%% Get api key
key(To) ->
  gen_mod:get_module_opt(To#jid.lserver,
    ?MODULE, iolist_to_binary([data(To, "Destination")]), fun(K) -> [iolist_to_binary(K)] end,
    list_to_binary("No api key")).

%% Filter types..
match(From, To, Packet) ->
  case data(Packet, "Type") of
    <<"chat">>      -> push(From, To, Packet);
    <<"groupchat">> -> push(From, To, Packet);
    _               -> false
  end.

%% URI
uri(From, To, Packet) ->
  _event = event(Packet),
  [ "apikey=", key(To), "&",
  "application=XMPP", "&",
  "event=New%20Event", "&",
  "description=", url_encode(_event), "&",
  "priority=0", "&",
  "url=xmpp:", data(From, "Destination")].

%% Callback
push(From, To, Packet) -> 
  _uri = uri(From, To, Packet),
  ?INFO_MSG("Push event: ~s", [_uri]),
  httpc:request(post, {"https://prowl.weks.net/publicapi/add", [], "application/x-www-form-urlencoded", list_to_binary(_uri)},[],[]).

%%% Following code is taken ejabberd_http.erl
url_encode(A) ->
  url_encode(A, <<>>).
url_encode(<<H:8, T/binary>>, Acc) when
    (H >= $a andalso H =< $z) orelse
    (H >= $A andalso H =< $Z) orelse
    (H >= $0 andalso H =< $9) orelse
    H == $_ orelse
    H == $. orelse
    H == $- orelse
    H == $/ orelse
    H == $: ->
  url_encode(T, <<Acc/binary, H>>);
url_encode(<<H:8, T/binary>>, Acc) ->
  case integer_to_hex(H) of
      [X, Y] -> url_encode(T, <<Acc/binary, $%, X, Y>>);
      [X] -> url_encode(T, <<Acc/binary, $%, $0, X>>)
  end;
url_encode(<<>>, Acc) ->
  Acc.
integer_to_hex(I) ->
  case catch erlang:integer_to_list(I, 16) of
    {'EXIT', _} -> old_integer_to_hex(I);
    Int -> Int
  end.
old_integer_to_hex(I) when I < 10 -> integer_to_list(I);
old_integer_to_hex(I) when I < 16 -> [I - 10 + $A];
old_integer_to_hex(I) when I >= 16 ->
  N = trunc(I / 16),
  old_integer_to_hex(N) ++ old_integer_to_hex(I rem 16).
