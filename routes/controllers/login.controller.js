var express = require('express');
var router = express.Router();
var pool = require('../../dbconf/pool.js');
var sql = require('../../dbconf/sqlMapping.js');

router.get('/', index);
router.post('/', userlogin);

//get
function index(req, res, next) {
    res.render('login');
}

//post
function userlogin(req, res, next) {
    var user = req.body;
    var status = 0;
    var message = '';
    pool.getConnection(function(err, connection) {
        if (err) {
            // handle error
            status = 0;
            message = 'Failed to connect to database';
            res.json({
                status : status,
                msg: message
            });
            return;
        }
        connection.query(
            sql.checkUserPassword, [user.username, user.password],
            function(err, result) {
                connection.release();
                if (err) {
                    // handle error
                    status = 0;
                    message = err.code + ' ' + err.sqlMessage;
                }
                if (result) {
                    if (result[0].userID < 0)
                    {
                        status = 0;
                        message = 'Failed to login';
                    }
                    else {
                        req.session.userID = result[0].userID;
                        status = 1;
                        message = req.session.userID;
                    }
                }
                res.json({status:status, msg:message});
                return;
            }
        );
    });
}

module.exports = router;