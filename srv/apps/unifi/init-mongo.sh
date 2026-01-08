#!/bin/bash
# .env에서 넘어온 변수를 사용해서 유저 생성
echo "Starting Init Script..."

mongo -u $MONGO_INITDB_ROOT_USERNAME -p $MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin <<EOS
use $MONGO_DBNAME;
db.createUser({
  user: "$MONGO_USER",
  pwd: "$MONGO_PASS",
  roles: [
    { role: "dbOwner", db: "$MONGO_DBNAME" },
    { role: "dbOwner", db: "${MONGO_DBNAME}_stat" },
    { role: "dbOwner", db: "${MONGO_DBNAME}_audit" }
  ]
});
EOS
echo "Init Script Finished."
