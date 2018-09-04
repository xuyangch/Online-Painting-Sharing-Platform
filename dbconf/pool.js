var mysql = require('mysql');

//创建连接池
var pool = mysql.createPool({
    host: 'localhost',
    user: 'xuyangch_root',
    password: 'x288zcxC@',
    database: 'xuyangch_dbproject',
    port: 3306,
    multipleStatements: true,
    connectionLimit: 150
});
module.exports = pool;
