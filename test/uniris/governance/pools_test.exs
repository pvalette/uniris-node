defmodule Uniris.Governance.PoolsTest do
  use UnirisCase

  alias Uniris.Governance.Pools

  alias Uniris.P2P
  alias Uniris.P2P.Node

  describe "members_of/1" do
    test "should return the list of nodes public keys for the miners pool " do
      P2P.add_node(%Node{
        ip: {127, 0, 0, 1},
        port: 3000,
        first_public_key: "key1",
        last_public_key: "key2"
      })

      assert ["key1"] = Pools.members_of(:miners)
    end
  end

  describe "member_of/1" do
    test "should return miners when the public key is a node public key" do
      P2P.add_node(%Node{
        ip: {127, 0, 0, 1},
        port: 3000,
        first_public_key: "key1",
        last_public_key: "key2"
      })

      assert :miners in Pools.member_of("key1")
    end
  end
end
