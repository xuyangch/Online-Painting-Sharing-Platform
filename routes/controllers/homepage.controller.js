var express = require('express');
var router = express.Router();
var mysql = require('mysql');
var pool = require('../../dbconf/pool.js');
var sql = require('../../dbconf/sqlMapping.js');
var jsonWrite = require('../../dbconf/jsonWrite.js');
var multer  = require('multer');
var fs = require('fs');
var upload = multer({ dest: 'uploads/' });
router.get('/', data);
router.get('/config', config);
router.patch('/config', configUpload);
router.patch('/password', passwordUpload);
router.patch('/charge', charge);
router.get('/following', following);
router.patch('/following', addFollowing);
router.delete('/following', delFollowing);
router.get('/collect', collect);
router.patch('/collect', addCollecting);
router.delete('/collect', delCollecting);
router.get('/contribute', contribute);
router.get('/addcontribute', addContribute);
router.delete('/contribute', delContribute);
router.get('/quit', quit);

function data(req, res, next) {
	var data = req.query;
	var userID = Number(data.userID);
	var sessionUserID = req.session.userID;
    if (!(userID)) userID = sessionUserID;
	//try multiple queries
    if (sessionUserID) {
        pool.getConnection(function (err, connection) {
            if (err) {
                // handle error
                res.render('error');
                return;
            }
            connection.query(
                sql.getContribute +
                sql.getUserName +
                sql.getFollowing +
                sql.getFollowingNum +
                sql.getCollectedPainting +
                sql.getMostTag +
                sql.getUserHeader +
                sql.getUserInfo +
                sql.getUserType,
                [userID, userID, userID, userID, userID, userID, userID, userID, userID]
                , function (err, result) {
                    connection.release();
                    if (err) {
                        // handle error
                        res.render('error');
                    }
                    if (result) {
                        pdata = {};
                        pdata.phomepage = result[7][0].phomepage;
                        pdata.abstract = result[7][0].abstract;
                        pdata.twitter = result[7][0].twitter;
                        res.render('homepage',
                            {
                                contribute_painting: result[0],
                                username: result[1][0].username,
                                following: result[2],
                                following_num: result[3][0].following_num,
                                collect_painting: result[4],
                                tag: result[5],
                                user_header: result[6][0].user_header,
                                userID: userID,
                                pdata: pdata,
                                type: result[8][0].type
                            });
                    }
                }
            );
        });
    }
    else
    {
        res.redirect('/login');
    }
}

//get
function config(req, res, next) {
    var userID = req.session.userID;
    if (userID)
    {
        pool.getConnection(function(err, connection) {
            if (err)
            {
                // handle error
                res.render('error');
                return;

            }
            connection.query(
                sql.getUserName +
                sql.getUserHeader +
                sql.getUserAlipay +
                sql.getUserMoney +
                sql.getUserInfo,
                [userID, userID, userID, userID, userID],
                function (err, result) {
                    connection.release();
                    if (err)
                    {
                        //error handler
                        res.render('error');
                    }
                    if (result)
                    {
                        res.render('config', {
                            username : result[0][0].username,
                            user_header : result[1][0].user_header,
                            alipay : result[2][0].alipay,
                            userID : req.session.userID,
                            frozen_money: result[4][0].frozen_money,
                            current_money: result[4][0].current_money,
                            twitter: result[5][0].twitter,
                            phomepage: result[5][0].phomepage,
                            abstract: result[5][0].abstract
                        });
                    }
                });

        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

//post
function configUpload(req, res, next) {
    var userID = req.session.userID;
    var newName = req.body.newname;
    var new_alipay = req.body.newAlipay;
    var twitter = req.body.twitter;
    var abstract = req.body.abstract;
    var phomepage = req.body.phomepage;
    var status = 0;
    var message = '';
    if (userID)
    {
        pool.getConnection(function(err, connection) {
            if (err)
            {
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
                sql.modifyUserBasicInfo +
                sql.modifyUserTwitter +
                sql.modifyUserAbstract +
                sql.modifyUserHomepage,
                [newName, new_alipay, userID, twitter,  userID, abstract,  userID, phomepage, userID],
                function (err, result) {
                    connection.release();
                    if (err)
                    {
                        //error handler
                        status = 0;
                        message = err.code + ' ' + err.sqlMessage;
                        res.json(
                            {
                                status : status,
                                msg : message
                            });
                        return;
                    }
                    if (result)
                    {
                        status = 1;
                        message = 'Successfully uploaded configs';
                        res.json(
                            {
                                status : status,
                                msg : message
                            });
                        return;
                    }
                });

        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

//post
function passwordUpload(req, res, next) {
    var userID = req.session.userID;
    var oldPassword = req.body.oldPassword;
    var newPassword = req.body.newPassword;
    var status = 0;
    var message = '';
    if (userID)
    {
        pool.getConnection(function(err, connection) {
            if (err)
            {
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
                sql.modifyUserPassword,
                [oldPassword, newPassword, userID],
                function (err, result) {
                    connection.release();
                    if (err)
                    {
                        //error handler
                        status = 0;
                        message = err.code + ' ' + err.sqlMessage;
                        res.json(
                            {
                                status : status,
                                msg : message
                            });
                        return;
                    }
                    if (result)
                    {
                        status = 1;
                        message = 'Successfully uploaded password';
                        res.json(
                            {
                                status : status,
                                msg : message
                            });
                        return;
                    }
                });

        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}


function following(req, res, next) {
    var userID = req.session.userID;
    var homepageID = req.query.userID;
    if (!(homepageID)) homepageID = userID;
    if (userID)
    {
        pool.getConnection(function(err, connection) {
            if (err) {
                // handle error
                res.render('error');
                return;
            }
            connection.query(
                sql.getUserName +
                sql.getUserHeader +
                sql.getFollowing +
                sql.getFollowingNum,
                [homepageID, homepageID, homepageID, homepageID],
                function (err, result) {
                    connection.release();
                    if (err) {
                        //handle error
                        res.render('error');
                    }
                    if (result) {
                        res.render('following', {
                            username : result[0][0].username,
                            user_header : result[1][0].user_header,
                            userID : homepageID,
                            following : result[2],
                            following_num : result[3][0].following_num,
                            isSelf : (userID == homepageID)
                        })
                    }
                });
        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

function addFollowing(req, res, next) {    
    var userID = req.session.userID;
    var followingID = req.body.userID;    
    var status = 0;
    var message = '';    
    if (userID)    
    {
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
            if (userID == followingID) {
                status = 0;
                message = 'You cannot follow yourself.';
                res.json({
                    status : status,
                    msg: message
                });
                return;
            } else {
                connection.query(
                    sql.addFollowing,
                    [userID, followingID],
                    function (err, result) {
                        connection.release();
                        if (err) {
                            //handle error
                            status = 0;
                            message = err.code + ' ' + err.sqlMessage;
                        }
                        if (result) {
                            //res.render('following', {})
                            status = 1;
                            message = 'Successfully followed a user';
                        }
                        res.json({
                            status : status,
                            msg: message
                        });
                        return;
                    });
            }
        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

function delFollowing(req, res, next) {    
    var userID = req.session.userID;    
    var followingID = req.query.userID;    
    console.log(userID)
    console.log(followingID)
    var status;
    var message;
    if (userID)
    {
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
                sql.delFollowing,
                [userID, followingID],
                function (err, result) {
                    connection.release();
                    if (err) {
                        //handle error
                        status = 0;
                        message = err.code + ' ' + err.sqlMessage;
                    }
                    if (result) {
                        //res.render('following', {})
                        status = 1;
                        message = 'Successfully unfollowed a user';
                    }
                    res.json({
                        status:status,
                        msg: message
                    });
                    return;
                });
        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

function collect(req, res, next) {
    var userID = req.session.userID;
    var homepageID = req.query.userID;
    if (!(homepageID)) homepageID = userID;
    if (userID)
    {
        pool.getConnection(function(err, connection) {
            if (err) {
                // handle error
                res.render('error');
                return;
            }
            connection.query(
                sql.getUserName +
                sql.getUserHeader +
                sql.getCollectedPainting +
                sql.getCollectedNum,
                [homepageID, homepageID, homepageID, homepageID],
                function (err, result) {
                    connection.release();
                    if (err) {
                        //handle error
                        res.render('error');
                    }
                    if (result) {
                        res.render('collect', {
                            username : result[0][0].username,
                            user_header : result[1][0].user_header,
                            userID : homepageID,
                            collect : result[2],
                            collect_num : result[3][0].collect_num,
                            isSelf : (userID == homepageID)
                        })
                    }
                });
        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

function addCollecting(req, res, next) {
    var userID = req.session.userID;
    var paintingID = req.body.paintingID;
    console.log(paintingID)
    var status = 0;
    var message = '';
    if (userID)
    {
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
                sql.addCollecting,
                [userID, paintingID],
                function (err, result) {
                    connection.release();
                    if (err) {
                        //handle error
                        status = 0;
                        message = err.code + ' ' + err.sqlMessage;
                    }
                    if (result) {
                        //res.render('following', {})
                        status = 1;
                        message = 'Successfully added collections';
                    }
                    res.json({
                        status : status,
                        msg: message
                    });
                    return;
                });
        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

function delCollecting(req, res, next) {
    var userID = req.session.userID;
    var paintingID = req.query.paintingID;
    var status = 0;
    var message = '';
    if (userID)
    {
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
                sql.delCollecting,
                [userID, paintingID],
                function (err, result) {
                    connection.release();
                    if (err) {
                        //handle error
                        status = 0;
                        message = err.code + ' ' + err.sqlMessage;
                    }
                    if (result) {
                        //res.render('following', {})
                        status = 1;
                        message = 'Successfully deleted collections';
                    }
                    res.json({
                        status : status,
                        msg: message
                    });
                    return;
                });
        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

function contribute(req, res, next) {
    var userID = req.session.userID;
    var homepageID = req.query.userID;
    if (!(homepageID)) homepageID = userID;
    if (userID)
    {
        pool.getConnection(function(err, connection) {
            if (err) {
                // handle error
                res.render('error');
                return;
            }
            connection.query(
                sql.getUserName +
                sql.getUserHeader +
                sql.getContribute +
                sql.getContributeNum,
                [homepageID, homepageID, homepageID, homepageID],
                function (err, result) {
                    connection.release();
                    if (err) {
                        //handle error
                        res.render('error');
                    }
                    if (result) {
                        res.render('contribute', {
                            username : result[0][0].username,
                            user_header : result[1][0].user_header,
                            userID : homepageID,
                            contribute : result[2],
                            contribute_num : result[3][0].contribute_num,
                            isSelf : (userID == homepageID)
                        })
                    }
                });
        });
    }
    else{
        //handle error
        res.redirect('/login');
    }
}

function addContribute(req, res, next) {
    var userID = req.session.userID;
    if (userID) {
        pool.getConnection(function (err, connection) {
            if (err) {
                // handle error
                res.render('error');
                return;
            }
            connection.query(
                sql.getUserName +
                sql.getUserHeader,
                [userID, userID]
                , function (err, result) {
                    connection.release();
                    if (err) {
                        // handle error
                        res.render('error');
                    }
                    if (result) {
                        res.render('addcontribute',
                            {
                                username: result[0][0].username,
                                user_header: result[1][0].user_header,
                                userID: userID
                            });
                    }
                }
            );
        });
    }
    else
    {
        res.redirect('/login');
    }
}


function delContribute(req, res, next) {
    var userID = req.session.userID;
    var paintingID = Number(req.query.paintingID);
    var status = 0;
    var message = '';
    if (userID)
    {
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
                sql.delContribute,
                [paintingID, userID],
                function (err, result) {
                    connection.release();
                    if (err) {
                        //handle error
                        status = 0;
                        message = err.code + ' ' + err.sqlMessage;
                    }
                    if (result) {
                        //res.render('following', {})
                        try {
                            fs.unlinkSync(__dirname + '/../../public' + result[0].paintingurl);
                            status = 1;
                            message = 'Successfully deleted painting';
                        } catch (err) {
                            if (err.code == 'ENOENT')
                            {
                                message = 'Painting does not exist!';
                            }
                        }
                    }
                    res.json({
                        status: status,
                        msg: message
                    });
                    return;
                });
        });
    }
    else
    {
        res.redirect('/login');
    }
}

//post
function charge(req, res, next) {
    var userID = req.session.userID;
    var money = req.body.money;
    var status = 0;
    var message = '';
    if (userID)
    {
        pool.getConnection(function(err, connection) {
            if (err) {
                // handle error
                status = 0;
                message = 'Failed to connect to database';
                res.json(
                    {
                        status: status,
                        msg: message
                    });
                return;
            }
            connection.query(
                sql.chargeMoney,
                [userID, money],
                function (err, result) {
                    connection.release();
                    if (err) {
                        status = 0;
                        message = 'Failed to add fund';
                    }
                    else {
                        status = 1;
                        message = 'Successfully added fund';
                    }
                    res.json(
                        {
                            status: status,
                            msg: message
                        });
                    return;
                }
            );
        });
    }
}

function quit(req, res, next) {
    if (req.session) {
        req.session.destroy(function(err) {
            if (err) {
                res.json({status: 0, msg: '退出失败'});
                return;
            }
            else {
                res.json({status: 1, msg: '退出成功'});
                return;
            }
        })
    }
}
module.exports = router;