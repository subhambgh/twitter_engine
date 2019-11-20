defmodule TwitterengineTest do
  use ExUnit.Case, async: true

  setup do
    server_pid = start_supervised!({TwitterEngine.Server,["abc"]})
    client_1_pid = start_supervised!({TwitterEngine.Client,{1,2,2}}, id: "client_1")
    client_2_pid = start_supervised!({TwitterEngine.Client,{2,2,2}}, id: "client_2")
    clients = [client_1_pid, client_2_pid]
    %{server: server_pid,clients: clients}
  end


  #====================  REGISTRATION TESTING =========================#
  test "Registration", %{server: server_pid,clients: clients} do
    
    assert [] = :ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    #IO.inspect :ets.lookup(:tab_user, 1)

    assert [{1, [], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
  end


  #====================  DELETE ACCOUNT TESTING =========================#
  test "De-Registration", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert [{1, [], [], "connected", 0}] =:ets.lookup(:tab_user, 1)

    GenServer.cast(Enum.at(clients,0),{:deRegister,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert [] =:ets.lookup(:tab_user, 1)
  end


  #====================  TWEET TESTING =========================#
  test "Tweet", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["foo", "bar"]})
    contains = Enum.member?(["foo", "bar"],:ets.lookup(:tab_tweet, tweetId))
    assert  contains=true
  end

  #====================  HASHTAG TESTING =========================#
  test "DoubleHashTag", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["#COP5615 is #great"]})
    assert [{"#COP5615", _}] = :ets.lookup(:tab_hashtag, "#COP5615")
    assert [{"#great", _}] = :ets.lookup(:tab_hashtag, "#great")
  end

 #====================  MENTIONS TESTING =========================# 
  test "DoubleMentions", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetId = GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@pranav is @hero"]})
    #IO.inspect :ets.tab2list(:tab_mentions)
    assert [{"@pranav", _}] = :ets.lookup(:tab_mentions, "@pranav")
    assert [{"@hero", _}] = :ets.lookup(:tab_mentions, "@hero")
  end

  #====================  QUERY TWEETS WITH HASHTAG TESTING =========================#
  test "Query-tweets with specific hashtags", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_tweet)

    tweetIdsWithHashHero = []
    tweetIdsWithoutHashHero = []
    tweetIdsWithHashHero ++ [GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@pranav is #hero"]})]
    tweetIdsWithHashHero ++ [GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@AlinDobra is #hero"]})]
    tweetIdsWithoutHashHero ++ [GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["#DOS is #great"]})]
    assert tweetIdsWithoutHashHero = elem(Enum.at(:ets.lookup(:tab_hashtag, "#hero"),0),1)
  end

  #====================  QUERY TEST WITH MENTIONS TESTING =========================#
  test "Query-tweets with specific mentions", %{server: server_pid,clients: clients} do
    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(server_pid)
    assert []=:ets.tab2list(:tab_mentions)

    tweetIdsWithMentionPranav = []
    tweetIdsWithoutMentionPranav = []
    tweetIdsWithMentionPranav ++ [GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@pranav is #champion"]})]
    tweetIdsWithMentionPranav ++ [GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@pranav is #hero"]})]
    tweetIdsWithoutMentionPranav ++ [GenServer.call(Enum.at(clients,0),{:tweet,server_pid,["@AlinDobra is #great"]})]
    assert tweetIdsWithMentionPranav = elem(Enum.at(:ets.lookup(:tab_mentions, "@pranav"),0),1)
  end

  #====================  SUBSCRIBER TESTING =========================#
  test "Subscribe",  %{server: server_pid,clients: clients} do
    
    assert [] = :ets.lookup(:tab_user, 1)
    assert [] = :ets.lookup(:tab_user, 2)

    GenServer.cast(Enum.at(clients,0),{:register,server_pid})
    GenServer.cast(Enum.at(clients,1),{:register,server_pid})

    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    GenServer.cast(Enum.at(clients,0),{:subscribe, server_pid, [2]})

    #IO.inspect Process.alive?(Enum.at(clients,1))
    :sys.get_state(Enum.at(clients,0))
    :sys.get_state(Enum.at(clients,1))
    :sys.get_state(server_pid)

    # IO.inspect ['==>', :ets.lookup(:tab_user, 1)]
    # IO.inspect ['===>', :ets.lookup(:tab_user, 1)]
    # IO.inspect ['==>', :ets.lookup(:tab_user, 2)]
    # IO.inspect ['===>', :ets.lookup(:tab_user, 2)]

    #adding to subscriber list
    assert [{1, [2], [], "connected", 0}] = :ets.lookup(:tab_user, 1)
    #adding to follower list
    assert [{2, [], [1], "connected", 0}] = :ets.lookup(:tab_user, 2)

  end

end
