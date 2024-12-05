#!/usr/bin/env sh

echo 'Running containers'
docker compose up -d  <<EOF
EOF

sleep 8
echo 'Initialize config server'
docker compose exec -T configSrv mongosh --port 27017 <<EOF

 rs.initiate(
  {
    _id : "config_server",
        configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
 exit();
EOF

sleep 8
echo 'Initialize shard1'
docker compose exec -T shard1 mongosh --port 27018 <<EOF

rs.initiate(
    {
      _id : "shard1-rs",
      members: [
        { _id : 0, host : "shard1:27018" },
        { _id : 1, host : "shard1-r1:27021" },
        { _id : 2, host : "shard1-r2:27022" },
        { _id : 3, host : "shard1-r3:27023" }
      ]
    }
);
exit();
EOF

sleep 8
echo 'Initialize shard2'
docker compose exec -T shard2 mongosh --port 27019 <<EOF

rs.initiate(
    {
      _id : "shard2-rs",
      members: [
        { _id : 0, host : "shard2:27019" },
        { _id : 1, host : "shard2-r1:27024" },
        { _id : 2, host : "shard2-r2:27025" },
        { _id : 3, host : "shard2-r3:27026" }
      ]
    }
  );
exit();
EOF

sleep 8
echo 'Filling data'
docker compose exec -T mongos_router mongosh --port 27020 <<EOF
 sh.addShard("shard1-rs/shard1:27018");
 sh.addShard("shard2-rs/shard2:27019");

 sh.enableSharding("somedb");
 sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

 use somedb

 for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

 db.helloDoc.countDocuments()
 exit();
EOF
