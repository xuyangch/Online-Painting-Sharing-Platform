create table buyer
(
	money double default '0' not null,
	id int not null
		primary key,
	frozen_money double default '0' not null
)
;

create table collection
(
	user int not null,
	painting int not null,
	primary key (user, painting)
)
;

create index collection_painting_fk
	on collection (painting)
;

create index collection_user_index
	on collection (user)
;

create table contribute
(
	user int not null,
	painting int not null,
	primary key (user, painting),
	constraint contribute_painting_uindex
		unique (painting)
)
;

create table follow
(
	follower int not null,
	followee int not null,
	primary key (follower, followee)
)
;

create index follow_followee_fk
	on follow (followee)
;

create table painter
(
	id int not null
		primary key,
	money double default '0' not null,
	frozen_money double default '0' null
)
;

alter table contribute
	add constraint contribute_painter_id_fk
		foreign key (user) references dbproject.painter (id)
;

create table painter_apply_for_trade
(
	painter int not null,
	trade int not null,
	primary key (painter, trade),
	constraint painter_apply_for_trade_painter_fk
		foreign key (painter) references dbproject.painter (id)
)
;

create index painter_apply_for_trade_trade_fk
	on painter_apply_for_trade (trade)
;

create trigger return_money_for_painter
             after DELETE on painter_apply_for_trade
             for each row
BEGIN
    DECLARE price_trade DOUBLE;
    SET price_trade = (SELECT price FROM trade WHERE id = OLD.trade);
    UPDATE painter SET money = money + price_trade/4, frozen_money = frozen_money -price_trade/4 WHERE id = OLD.painter;
  END;

create table painting
(
	id int not null auto_increment
		primary key,
	topic varchar(20) not null,
	upload_time datetime default CURRENT_TIMESTAMP not null,
	width int default '0' null,
	length int default '0' null,
	upvote int default '0' null,
	page_view int default '0' null,
	url varchar(128) default 'default painting location' null
)
;

alter table collection
	add constraint collection_painting_id_fk
		foreign key (painting) references dbproject.painting (id)
;

alter table contribute
	add constraint contribute_painting_id_fk
		foreign key (painting) references dbproject.painting (id)
;

create table painting_tag
(
	painting int not null,
	tag varchar(50) not null,
	primary key (painting, tag),
	constraint painting_tag_painting_id_fk
		foreign key (painting) references dbproject.painting (id)
)
;

create index painting_tag_tag_tag_fk
	on painting_tag (tag)
;

create trigger add_tag_for_painting
             before INSERT on painting_tag
             for each row
BEGIN
    if (NOT exists(
      SELECT *
      FROM tag
      WHERE (tag.tag = NEW.tag)
    )) THEN
      INSERT INTO tag (tag) VALUES (NEW.tag);
    END IF;
  END;

create table tag
(
	tag varchar(50) not null
		primary key
)
;

alter table painting_tag
	add constraint painting_tag_tag_tag_fk
		foreign key (tag) references dbproject.tag (tag)
;

create table trade
(
	id int not null auto_increment
		primary key,
	description varchar(500) null,
	price double not null,
	create_time datetime default CURRENT_TIMESTAMP not null,
	finish_time datetime default '2099-12-31 23:59:59' null,
	deadline datetime not null,
	status varchar(20) not null,
	buyer int not null,
	responder int null,
	upload_file_route varchar(64) null,
	constraint trade_buyer_id_fk
		foreign key (buyer) references dbproject.buyer (id),
	constraint trade_painter_id_fk
		foreign key (responder) references dbproject.painter (id)
)
;

create index trade_buyer_fk
	on trade (buyer)
;

create index trade_responder_fk
	on trade (responder)
;

create trigger froze_money_trigger
             after INSERT on trade
             for each row
BEGIN
    UPDATE buyer
      SET money = money - NEW.price,
          frozen_money = frozen_money + NEW.price
    WHERE id = NEW.buyer;
  END;

create trigger check_validity_trade_trigger
             before INSERT on trade
             for each row
BEGIN
    DECLARE msg VARCHAR(128);
    if (NEW.price < 0) OR (NEW.price > (SELECT money from buyer WHERE buyer.id = NEW.buyer))
    THEN
      set msg = 'check_validity_trade_trigger Error, trade not valid';
      signal sqlstate '45000' set message_text = msg;
    END IF;
  END;

alter table painter_apply_for_trade
	add constraint painter_apply_for_trade_trade_fk
		foreign key (trade) references dbproject.trade (id)
;

create table trade_tag
(
	trade int not null,
	tag varchar(20) not null,
	primary key (trade, tag),
	constraint trade_tag_trade_fk
		foreign key (trade) references dbproject.trade (id),
	constraint trade_tag_tag_fk
		foreign key (tag) references dbproject.tag (tag)
)
;

create index trade_tag_tag_fk
	on trade_tag (tag)
;

create trigger add_tag_for_trade_trigger
             before INSERT on trade_tag
             for each row
BEGIN
    if (NOT exists(
      SELECT *
      FROM tag
      WHERE (tag.tag = NEW.tag)
    )) THEN
      INSERT INTO tag (tag) VALUES (NEW.tag);
    END IF;
  END;

create table upvote
(
	user int not null,
	painting int not null,
	primary key (user, painting),
	constraint upvote_painting_id_fk
		foreign key (painting) references dbproject.painting (id)
)
;

create index upvote_painting_id_fk
	on upvote (painting)
;

create table user
(
	id int not null auto_increment
		primary key,
	username varchar(50) not null,
	type char default 'o' not null,
	password varchar(256) not null,
	alipay_address varchar(50) null,
	icon varchar(128) default 'default icon location' not null,
	phomepage varchar(128) null,
	twitter varchar(50) null,
	abstract varchar(1024) null,
	constraint user_id_uindex
		unique (id),
	constraint user_username_uindex
		unique (username)
)
;

create index user_user_type_type_fk
	on user (type)
;

create trigger ensure_alipay_regist
             before INSERT on user
             for each row
BEGIN
    DECLARE msg VARCHAR(128);
    if (NEW.type = 'p') AND (isnull(NEW.alipay_address)) THEN
      set msg = concat('ensure_alipay_regist Trigger Error: Trying to insert a painter with no alipay account');
      signal sqlstate '45000' set message_text = msg;
      ELSE if (NEW.type = 'b') AND (isnull(NEW.alipay_address)) THEN
        set msg = concat('ensure_alipay_regist Trigger Error: Trying to insert a buyer with no alipay account');
        signal sqlstate '45000' set message_text = msg;
      END IF;
    END IF;
  END;

create trigger add_user_info
             after INSERT on user
             for each row
BEGIN

    IF (NEW.type = 'p') THEN

      INSERT INTO painter(id) VALUE(NEW.id);

    END IF;

    IF (NEW.type = 'b') THEN

      INSERT INTO buyer(id) VALUE (NEW.id);

    END IF;

  END;

alter table buyer
	add constraint buyer_user_id_fk
		foreign key (id) references dbproject.user (id)
;

alter table collection
	add constraint collection_user_id_fk
		foreign key (user) references dbproject.user (id)
;

alter table follow
	add constraint follow_user_id_fk
		foreign key (follower) references dbproject.user (id)
;

alter table follow
	add constraint follow_user_id_fk_2
		foreign key (followee) references dbproject.user (id)
;

alter table painter
	add constraint painter_user_id_fk
		foreign key (id) references dbproject.user (id)
;

alter table upvote
	add constraint upvote_user_id_fk
		foreign key (user) references dbproject.user (id)
;

create table user_type
(
	type char not null
		primary key
)
;

alter table user
	add constraint user_user_type_type_fk
		foreign key (type) references dbproject.user_type (type)
;

create procedure addContribute (IN in_topic varchar(20), IN in_user int, IN in_format varchar(5), OUT p_id int)  
BEGIN
    START TRANSACTION ;
    BEGIN
    DECLARE p_format VARCHAR(128);
    DECLARE err_msg VARCHAR(128);
    SET err_msg = concat('Add Contribute Error: Input ID is not a painter');
    IF (isnull((SELECT id FROM painter WHERE id = in_user))) THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = err_msg;
    END IF;
    INSERT INTO painting(topic) VALUES (in_topic);
    SET p_id = (SELECT max(id) FROM painting);
    SET p_format = (concat('/img/painting/',p_id,in_format));
    UPDATE painting SET url = p_format WHERE id = p_id;
    INSERT INTO contribute (user, painting) VALUES (in_user,p_id);
    END ;
    COMMIT ;
  END;

create procedure addTrade (IN in_des varchar(500), IN in_pri double, IN in_ddl datetime, IN in_sta varchar(20), IN in_buyer int, OUT tradeID int)  
BEGIN
    START TRANSACTION ;
    BEGIN
    IF (isnull((SELECT id FROM buyer WHERE id = in_buyer))) THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Add Trade Error: No such buyer exists!";
    END IF;
    IF (in_ddl <= current_timestamp)THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Add Trade Error: DDL is invalid!";
    END IF;
    INSERT INTO trade(description, price, deadline, status, buyer) VALUES (in_des,in_pri,in_ddl,in_sta,in_buyer);
    SET tradeID = (SELECT max(id) FROM trade);
    END ;
    COMMIT ;
  END;

create procedure addTradeWork (IN in_painterID int, IN in_tradeID int, IN in_format varchar(5))  
BEGIN
    IF (isnull((SELECT id FROM trade WHERE id = in_tradeID and responder = in_painterID))) THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Add Trade Work Error: Illigal Input!";
    END IF;
    IF (((SELECT status FROM trade WHERE id = in_tradeID) LIKE 'Creating') OR ((SELECT status FROM trade WHERE id = in_tradeID) LIKE 'Complete'))THEN
      UPDATE trade SET upload_file_route = concat('/img/tradework/',in_tradeID,in_format), status = 'Complete' WHERE id = in_tradeID;
    ELSE 
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Add Trade Work Error: Illigal Status!";
    END IF ;
  END;

create procedure addUser (IN in_username varchar(50), IN in_type char, IN in_password varchar(15), IN in_alipay varchar(50), OUT userID int)  
BEGIN
    START TRANSACTION ;
    BEGIN
      INSERT INTO user(username,type,password,alipay_address) VALUES(in_username,in_type,hex(aes_encrypt(in_password,unhex(sha2('MySecretKey',256)))),in_alipay);
      SET userID = (SELECT max(id) FROM user);
      UPDATE user SET icon = (concat('/img/header/',userID,'.png')) WHERE id = userID;
    END;
    COMMIT;
  END;

create procedure buyer_add_money (IN buyer_id int, IN money_added double)  
BEGIN
    IF ((SELECT type FROM user WHERE id = buyer_id) LIKE 'o')THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Buyer Add Money Error: Not a buyer!";
    ELSEIF ((SELECT type FROM user WHERE id = buyer_id) LIKE 'b')THEN
      UPDATE buyer
        SET money = money + money_added
      WHERE id = buyer_id;
    ELSE
      UPDATE painter
        SET money = money + money_added
      WHERE id = buyer_id;
    END IF;
  END;

create procedure buyer_decide_painter (IN in_tradeID int, IN in_painterID int, IN in_buyerID int)  
BEGIN
    DECLARE price_for_trade DOUBLE;
    IF (isnull((SELECT id FROM trade WHERE buyer = in_buyerID AND id = in_tradeID)))THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Buyer Decide Painter Error: Current buyer do not have authority!";
    END IF;
    IF (isnull((SELECT id FROM painter WHERE id = in_painterID))) THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Buyer Decide Painter Error: Current painter do not have authority!";
    END IF;
    IF (isnull((SELECT painter FROM painter_apply_for_trade WHERE painter = in_painterID and trade = in_tradeID))) THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Buyer Decide Painter Error: Current painter has not applied for this trade!";
    END IF;
    IF (NOT ((SELECT status FROM trade WHERE id = in_tradeID) LIKE 'Calling'))THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Buyer Decide Painter Error: Can not decide in current state!";
    END IF;
    UPDATE trade
      SET responder = in_painterID, status = 'Creating'
    WHERE id = in_tradeID;
    SET price_for_trade = (SELECT price FROM trade WHERE id = in_tradeID);
    DELETE FROM painter_apply_for_trade WHERE trade = in_tradeID;
    UPDATE painter SET money = money - price_for_trade/4, frozen_money = frozen_money + price_for_trade/4 WHERE id = in_painterID;
  END;

create procedure cancelTrade (IN in_userID int, IN in_tradeID int)  
BEGIN
    DECLARE found_buyer INT;
    DECLARE found_painter INT;
    DECLARE found_state VARCHAR(20);
    DECLARE f_money DOUBLE;
    DECLARE flag INT;
    SET flag = 1;
    SET found_buyer = (SELECT buyer FROM trade WHERE (buyer = in_userID or responder = in_userID) and id = in_tradeID);
    SET found_painter = (SELECT responder FROM trade WHERE (buyer = in_userID or responder = in_userID) and id = in_tradeID);
    SET found_state = (SELECT status FROM trade WHERE (buyer = in_userID or responder = in_userID) and id = in_tradeID);
    IF (isnull(found_buyer))THEN
      IF (isnull((SELECT painter FROM painter_apply_for_trade WHERE in_userID = painter and in_tradeID = trade))) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Cancel Trade Error: Illigal Input!";
      END IF;
      DELETE FROM painter_apply_for_trade WHERE in_tradeID = trade and in_userID = painter;
      SET flag = 0;
    END IF;
    IF (flag) THEN
    IF (found_state LIKE 'Calling') THEN
      IF (in_userID = found_buyer)THEN
        UPDATE trade SET status = 'TradeFail' WHERE id = in_tradeID;
        SET f_money = (SELECT price FROM trade WHERE id = in_tradeID);
        DELETE FROM painter_apply_for_trade WHERE trade = in_tradeID;
        UPDATE buyer SET money = money + f_money, frozen_money = frozen_money-f_money WHERE id = found_buyer;
      ELSE
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Cancel Trade Error: Painter can not cancel at calling state!";
      END IF;
    ELSEIF (found_state LIKE 'Creating') THEN
      IF (in_userID = found_buyer)THEN
        UPDATE trade SET status = 'TradeFail' WHERE id = in_tradeID;
        SET f_money = (SELECT price FROM trade WHERE id = in_tradeID);
        UPDATE painter SET money = money + 3*f_money/4, frozen_money = frozen_money-f_money/4 WHERE id = found_painter;
        UPDATE buyer SET money = money + f_money/2, frozen_money = frozen_money-f_money WHERE id = found_buyer;
      ELSE
        UPDATE trade SET status = 'TradeFail' WHERE id = in_tradeID;
        SET f_money = (SELECT price FROM trade WHERE id = in_tradeID);
        UPDATE painter SET frozen_money = frozen_money-f_money/4 WHERE id = found_painter;
        UPDATE buyer SET money = money + 5*f_money/4, frozen_money = frozen_money-f_money WHERE id = found_buyer;
      END IF;
    ELSEIF (found_state LIKE 'Complete') THEN
      IF (in_userID = found_buyer)THEN
        UPDATE trade SET status = 'TradeFail' WHERE id = in_tradeID;
        SET f_money = (SELECT price FROM trade WHERE id = in_tradeID);
        UPDATE painter SET money = money + 5*f_money/4, frozen_money = frozen_money-f_money/4 WHERE id = found_painter;
        UPDATE buyer SET frozen_money = frozen_money-f_money WHERE id = found_buyer;
      ELSE
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Cancel Trade Error: Painter can not cancel at complete state!";
      END IF;
    ELSE
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Cancel Trade Error: Can not cancel at current state!";
    END IF;
    END IF;
  END;

create function checkUserPassword (in_username varchar(50), in_userpassword varchar(15)) returns int 
BEGIN
    DECLARE userID INT;
    DECLARE temp_password VARCHAR(256);
    DECLARE user_password VARCHAR(256);
    SET temp_password = hex(aes_encrypt(in_userpassword,unhex(sha2('MySecretKey',256))));
    SET user_password = (SELECT password FROM user WHERE username = in_username);
    IF ((SELECT user_password LIKE temp_password)) THEN
      SET userID = (SELECT id FROM user WHERE username = in_username);
    ELSE
      SET userID = -1;
    END IF;
    RETURN userID;
  END;

create procedure completeTrade (IN in_buyerID int, IN in_tradeID int)  
BEGIN
    DECLARE found_status VARCHAR(20);
    DECLARE found_responder INT;
    DECLARE found_price DOUBLE;
    SET found_status = (SELECT status FROM trade WHERE buyer = in_buyerID and id = in_tradeID);
    IF (isnull(found_status))THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT  = "Complete Trade Error: User do not have authority!";
    END IF;
    IF (NOT (found_status LIKE 'Complete'))THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT  = "Complete Trade Error: Unable to complete at current state!";
    END IF;
    SET found_responder = (SELECT responder FROM trade WHERE buyer = in_buyerID and id = in_tradeID);
    SET found_price = (SELECT price FROM trade WHERE buyer = in_buyerID and id = in_tradeID);
    UPDATE trade SET status = 'TradeSucceed' WHERE id = in_tradeID;
    UPDATE buyer SET frozen_money = frozen_money - found_price WHERE id = in_buyerID;
    UPDATE painter SET money = money + 5*(found_price/4) WHERE id = found_responder;
    UPDATE painter SET frozen_money = (frozen_money - (found_price/4)) WHERE id = found_responder;
  END;

create function delContribute (paintingID int, userID int) returns varchar(128) 
BEGIN

    DECLARE paintingurl VARCHAR(128);

    DECLARE msg VARCHAR(128);

    SET paintingurl = (SELECT url FROM painting p, contribute c WHERE c.user=userID and c.painting = paintingID and p.id = c.painting );

    IF (isnull(paintingurl)) THEN

      SET msg = concat("Delete Contribute Error: No such contribute record!");

      SIGNAL SQLSTATE '45001' SET message_text = msg;

    ELSE

      DELETE FROM contribute WHERE user = userID AND painting = paintingID;

      DELETE FROM collection WHERE painting = paintingID;
      
      DELETE FROM painting_tag WHERE painting = paintingID;

      DELETE FROM painting WHERE id = paintingID;

      RETURN paintingurl;

    END IF;

  END;

create function delPaintingTag (in_paintingID int, in_paintingTag varchar(20), in_userID int) returns int 
BEGIN
    DECLARE status INT;
    DECLARE paintingID INT;
    DECLARE error_msg_1 VARCHAR(128);
    DECLARE error_msg_2 VARCHAR(128);
    SET error_msg_1 = concat("Delete Painting Tag Error: Current user don't have authority!");
    SET error_msg_2 = concat("Delete Painting Tag Error: No such tag exists for this painting!");
    SET paintingID = (SELECT painting FROM contribute WHERE user = in_userID AND painting = in_paintingID);
    IF (isnull(paintingID)) THEN
      #SET status = 0;
      SIGNAL SQLSTATE '45001' SET message_text = error_msg_1;
    ELSE
      SET paintingID = (SELECT painting FROM painting_tag WHERE painting = in_paintingID AND tag = in_paintingTag);
      IF (isnull(paintingID)) THEN
        SIGNAL SQLSTATE '45001' SET message_text = error_msg_2;
      END IF;
      DELETE FROM painting_tag WHERE painting = in_paintingID AND tag = in_paintingTag;
      SET status = 1;
      RETURN status;
    END IF;
  END;

create function getBuyerFlag (in_userID int) returns int 
BEGIN
    DECLARE type_get CHAR;
    SET type_get = (SELECT type FROM user WHERE in_userID = id);
    IF ((SELECT type_get LIKE 'b')) THEN 
      RETURN 1;
    ELSE 
      RETURN 0;
    END IF;
  END;

create function getInUser () returns int 
BEGIN 
    RETURN @inuserid;
  END;

create procedure getRelatedTrades ()  
BEGIN
    IF (NOT isnull((SELECT id FROM painter WHERE id = getInUser())))THEN
      DROP VIEW IF EXISTS painterTradeInfo;
      CREATE VIEW painterTradeInfo AS SELECT buyer, deadline AS ddl, price, status AS state, username AS buyername, 'responder' AS relation,t.id AS tradeID FROM trade t, user u WHERE t.responder = getInUser() and t.buyer = u.id UNION SELECT buyer, deadline, price, status AS state, username AS buyername, 'applier' AS relation, t.id AS tradeID FROM trade t, user u, painter_apply_for_trade p WHERE p.painter = getInUser() and p.trade = t.id and u.id = t.buyer;
      SELECT * FROM painterTradeInfo;
    ELSEIF (NOT isnull((SELECT id FROM buyer WHERE id = getInUser())))THEN
      DROP VIEW IF EXISTS buyerTradeInfo;
      CREATE VIEW buyerTradeInfo AS SELECT buyer, deadline AS ddl, price, status AS state, username AS buyername, 'buyer' AS relation, t.id AS tradeID FROM trade t, user u WHERE t.buyer = getInUser() and t.buyer = u.id;
      SELECT * FROM buyerTradeInfo;
    ELSE
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT  = "Get Related Trade Error: Not buyer or painter";
    END IF;
  END;

create procedure getTradeUrl (IN in_userID int, IN in_tradeID int, OUT out_url varchar(128))  
BEGIN
    IF (isnull((SELECT id FROM trade WHERE id = in_tradeID and buyer = in_userID))) THEN
      SET out_url = NULL;
    ELSE
      SET out_url = (SELECT upload_file_route FROM trade WHERE id = in_tradeID);
    END IF;
  END;

create procedure getUserMoney (IN userID int, OUT frozenMoney double, OUT currentMoney double)  
BEGIN
    IF ((SELECT type FROM user WHERE id = userID) LIKE 'o') THEN
      SET frozenMoney = 0;
      SET currentMoney = 0;
    ELSEIF ((SELECT type FROM user WHERE id = userID) LIKE 'b') THEN
      SET frozenMoney = (SELECT frozen_money FROM buyer WHERE id = userID);
      SET currentMoney = (SELECT money FROM buyer WHERE id = userID);
    ELSE
      SET frozenMoney = (SELECT frozen_money FROM painter WHERE id = userID);
      SET currentMoney = (SELECT money FROM painter WHERE id = userID);
    END IF;
  END;

create procedure modifyResolution (IN in_length int, IN in_width int, IN in_userID int, IN in_paintingID int)  
BEGIN 
    IF (isnull((SELECT user FROM contribute WHERE user = in_userID and painting = in_paintingID))) THEN 
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Modify Resolution Error: User Do Not Have Authority";
    END IF;
    UPDATE painting SET length = in_length, width = in_width WHERE id = in_paintingID;
  END;

create function modifyUserPassword (in_oldUserPassword varchar(15), in_newUserPassword varchar(15), in_userID int) returns int 
BEGIN
    DECLARE orgPassword VARCHAR(15);
    DECLARE msg VARCHAR(50);
    SET msg = concat("Modify User Password Error: Password is invalid!");
    SET orgPassword = (SELECT password FROM user WHERE id = in_userID);
    IF ((SELECT orgPassword LIKE in_oldUserPassword)) THEN
      UPDATE user SET password = in_newUserPassword WHERE id = in_userID;
    ELSE
      SIGNAL SQLSTATE '45001' SET message_text = msg;
    END IF;
    RETURN 1;
  END;

create procedure painter_apply_for_trade (IN in_painterID int, IN in_tradeID int)  
BEGIN 
    DECLARE price_for_trade DOUBLE;
    IF (isnull((SELECT id FROM painter WHERE id = in_painterID))) THEN 
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Painter Apply For Trade Error: Not A Painter!";
    END IF;
    IF (isnull((SELECT id FROM trade WHERE id = in_tradeID))) THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Painter Apply For Trade Error: No Such Trade!";
    END IF;
    IF (NOT ((SELECT status FROM trade WHERE id = in_tradeID) LIKE 'Calling')) THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Painter Apply For Trade Error: Can Not Apply At Current Status!";
    END IF;
    SET price_for_trade = (SELECT price FROM trade WHERE id = in_tradeID);
    IF ((SELECT money FROM painter WHERE id = in_painterID) < price_for_trade/4) THEN 
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "Painter Apply For Trade Error: Do not have enough money!";
    END IF;
    UPDATE painter SET money = money - price_for_trade/4, frozen_money = frozen_money + price_for_trade/4 WHERE id = in_painterID;
    INSERT INTO painter_apply_for_trade (painter, trade) VALUES (in_painterID,in_tradeID);
  END;

CREATE EVENT ddl_exceeds
  ON SCHEDULE
  EVERY 5 MINUTE
  DO
  BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE currentState VARCHAR(20);
    DECLARE currentTradeID INT;
    DECLARE currentDDL DATETIME;
    DECLARE currentBuyer INT;
    DECLARE currentResponder INT;
    DECLARE rs CURSOR FOR SELECT status, id, deadline FROM trade;
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
    OPEN rs;
    read_loop :LOOP
      FETCH rs INTO currentState, currentTradeID, currentDDL;
      IF (done)THEN
        LEAVE read_loop;
      END IF;
      IF (currentDDL < current_timestamp)THEN
        SET currentBuyer = (SELECT buyer FROM trade WHERE id = currentTradeID);
        IF (currentState LIKE 'Calling')THEN
          CALL cancelTrade(currentBuyer,currentTradeID);
        ELSEIF (currentState LIKE 'Creating')THEN 
          SET currentResponder = (SELECT responder FROM trade WHERE id = currentTradeID);
          CALL cancelTrade(currentResponder, currentTradeID);
        ELSEIF (currentState LIKE 'Complete')THEN 
          CALL completeTrade(currentBuyer, currentTradeID);
        END IF;
      END IF;
    END LOOP read_loop;
    CLOSE rs;
  END;