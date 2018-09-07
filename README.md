# Online Painting Sharing Platform
Vixip is a social network that allows people to share, trade, search and add tags for their paintings. The initial 10 GB of the data of users and paintings are crawled from Pixiv. The website is developed using HTML, CSS, JavaScript and MySQL.

# Table of Contents
<!-- TOC -->

- [Online Painting Sharing Platform](#online-painting-sharing-platform)
- [Table of Contents](#table-of-contents)
- [Starting the Node Server](#starting-the-node-server)
- [Website Screenshots](#website-screenshots)
    - [Login](#login)
    - [Sign Up](#sign-up)
    - [Homepage](#homepage)
    - [User Add Upload Page](#user-add-upload-page)
    - [User All Uploads Page](#user-all-uploads-page)
    - [User Collection Page](#user-collection-page)
    - [User Following Page](#user-following-page)
    - [User Setting Page](#user-setting-page)
    - [Painting Homepage](#painting-homepage)
    - [Painting Search Page](#painting-search-page)
    - [User Search Page](#user-search-page)
    - [Trade Search Page](#trade-search-page)
    - [User' s Trade Page](#user-s-trade-page)
    - [All Trades Page](#all-trades-page)
    - [Trade Initialization Page](#trade-initialization-page)
    - [Trade Detail Page](#trade-detail-page)
    - [User Upload for Trade Page](#user-upload-for-trade-page)
- [Brief Introduction](#brief-introduction)
    - [E/R Model of the System](#er-model-of-the-system)
    - [State Transition Diagram for Trading System](#state-transition-diagram-for-trading-system)
    - [Triggers, Events, Functions and Procedures for Database](#triggers-events-functions-and-procedures-for-database)
        - [Triggers](#triggers)
        - [Events](#events)
        - [Functions and Procedures](#functions-and-procedures)
            - [Functions and Procedures Related to Trades](#functions-and-procedures-related-to-trades)
            - [Functions and Procedures Related to Paintings and Users](#functions-and-procedures-related-to-paintings-and-users)

<!-- /TOC -->

# Starting the Node Server
To run the node server, you' ll need to first change the setting of MySQL database in app.js and dbconfig/pool.js. Then, in the project root folder, simply type:
```
npm install
npm start
```
# Website Screenshots
:warning: Since all URLs have now been modified to follow REST API design pattern, all current URLs of Vixip may be different from the URLs shown in the screenshots.
## Login
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/alluploads.png)
## Sign Up
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/signup.png)

## Homepage
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/homepage.png)

## User Add Upload Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/pageupload.png)

## User All Uploads Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/alluploads.png)

## User Collection Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/usercollection.png)

## User Following Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/userfollowing.png)

## User Setting Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/usersetting.png)

## Painting Homepage
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/painting.png)

## Painting Search Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/paintingsearch.png)

## User Search Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/usersearch.png)

## Trade Search Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/tradesearch.png)

## User' s Trade Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/trade.png)
 ## All Trades Page
 ![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/alltrades.png)

## Trade Initialization Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/inittrade.png)

## Trade Detail Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/tradedetail.png)

## User Upload for Trade Page
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/screenshots/uploadtrade.png)

# Brief Introduction
## E/R Model of the System
![](https://github.com/chyacinth/MarkdownPhotos/blob/master/vixip/er_graph.png?raw=true)

As shown in the graph, there are 4 entities in our ER diagram, including: painting, trade, tags, users, and 3 sub-categories under the user entity: visitors, painters, and buyers(initiators). These three users have different Privileges, and our database and web pages will behave differently when they visit the website.

The relations between each table in MySQL database is shown in the diagram below:
![](https://github.com/chyacinth/MarkdownPhotos/blob/master/vixip/mysql_tables.png?raw=true)

The diagram clearly demonstrates what how each entities are formed in our database from E/R graph.

## State Transition Diagram for Trading System
The trading system in the website mimics how a trade works in real word.
![](https://raw.githubusercontent.com/chyacinth/MarkdownPhotos/master/vixip/trade_state_transfer.png)


[0] Freeze the buyer's funds equaling to the trade price as deposit

[1] Freeze the candidate's funds equaling to 1/4 of the trade price as a deposit

[2]Return the deposits of other unselected candidates

[3] Buyers pays the responder using his frozen funds, the responder gets his deposits and salaries from buyer

[4] The deposit paid by the responder in the trade was deducted, and the buyer gets his deposit back and received 1/4 of the transaction price from the responder as compensation.

[5] The buyer gets 1/2 of his deposit, and the responder gets 1/2 of the price of the trade as compensation.

[6] All the deposit paid by the buyer for this trade is deducted, and the responder gets his deposit and receives funds equivalent to the transaction price as compensation.

[7] The buyer gets his deposit and all applicants gets their deposit back.

## Triggers, Events, Functions and Procedures for Database
To ensure data integrity, there are a great number of triggers, events, functions and procedures in the database.
### Triggers
| Trigger Name   | Trigger Type | Trigger Usage |
| -------------------- | ---------------- | ------------- |
| Return_money_for_painter | After Trigger | Returns deposit to candidates after each time a candidates is removed.|
|Add_tag_for_painting| Before Trigger| Adds tag to the Tag table before adding the painting.|
|Add_tag_for_trade_trigger|Before Trigger|Adds tag to the Tag table before adding the trade.|
|Check_validity_trade_trigger|Before Trigger|Check whether the trade to be initiated is legal before adding it.|
|Froze_money_trigger|After Trigger|Freeze part of the buyer' s funds after he initiates a trade.|
|Add_user_info|After Trigger|Add the user to painter or buyer table after adding him to user table. |
|Ensure_alipay_regist|Before Trigger|Ensure buyers and painters have filled their Alipay account before register them into the database.|

### Events
| Event Name   | Usage |
| -------------------- | ---------------- |
| DDL_exceeds | Called every 5 minutes and will read each entry in the trading table to check whether any trade has met its deadline and will cancel or finish the trade according to its status. |

### Functions and Procedures
:warning: Input and output arguments are omitted. If you are interested in the detail of functions and procedures, see the [code](https://github.com/chyacinth/Online-Painting-Sharing-Platform/blob/master/additional/dbCode/database_v2.5.sql) for database establishment.
#### Functions and Procedures Related to Trades 
| Functions or Procedure Name   | Usage |
| -------------------- | ---------------- |
|addTrade| Add a newly initiated trade into trade table |
|addTradeWork| Add the location of the painting uploaded by the responder into trade table|
|buyer_decide_painter| A buyer chooses a responder from candidates. It also performs privilege check for the user (whether the user has the privilege to do certain operations according to his status ) and trade state checking according to the state transition diagram. |
|cancelTrade|A user cancels a trade. The user ID must match one party of the trade and arrange the funds according to the state transition diagram. |
|completeTrade|A buyer completes a trade. The buyer ID and trade ID must match. The status of the trade will change according to the state transition diagram.|
|getRelatedTrades|Read all information related to input user ID.|
|getTradeUrl|Get the URL of the painting for trade.|
|getUserMoney|Return the funds of a painter or buyer. Also perform privilege check. |
|painter_apply_for_trade| Add painter id and trade id into painter_apply_for_trade table. Perform user privilege check and confirm the trade status to be collecting and add froze deposit of the painter.|

#### Functions and Procedures Related to Paintings and Users 
| Event Name   | Usage |
| -------------------- | ---------------- |
|addContribute|Add the information of painting into painting table. Perform privilege check.|
|addUser|Add new user. Perform privilege check. Also check duplicate username.|
|buyer_add_money| Add funds for buyer and painter. Perform privilege check.|
|checkUserPassword|Check whether the password matches username in user table|
|delContribute|Delete the painting uploaded by the painter. Perform privilege check (only the owner of the painting has the privilege). Also delete all tags, collection information, contribute information from the database|
|delPaintingTag|Delete the tag of a painting. Perform privilege check (only the owner of the painting has the privilege). And the painting must has that tag before deleting.|
|getBuyerFlag|Return whether the user is buyer.|
|modifyResolution|Modify the resolution of a painting. Perform privilege check (only the owner of the painting has the privilege).|
|modifyUserPassword|Check whether old password matches username. Then modifies user password. |