var tools = require('./crawlerTools');
var fs = require('fs');
var db = require('./mongoDB');

var illustQueue = [];
var hashIllust = {};
var result;

async function main() {
    console.log(illustQueue);
    while (illustQueue.length != 0) {
        ID = illustQueue[0];
        if (hashIllust[ID] == 1) {
            illustQueue.shift();
            continue;
        }
        console.log(ID);
        result = await tools.getIllust(ID);
        result["illustID"] = ID;
        // fs.writeFile("test.txt", JSON.stringify(result), function(err) {
        //     if (err) {
        //         console.log("Error!");
        //     }
        //     console.log('Saved.');
        // });
        db.insert(result, 'illust');
        hashIllust[illustQueue.shift()] = 1;
    }
}


if (process.platform === "win32") {
    var rl = require("readline").createInterface({
        input: process.stdin,
        output: process.stdout
    });

    rl.on("SIGINT", function() {
        process.emit("SIGINT");
    });
}

process.on("SIGINT", function() {
    //graceful shutdown
    fs.writeFileSync("illustQueue.txt", JSON.stringify(illustQueue), function(err) {
        if (err) {
            console.log("Error!");
        }
        console.log('Saved.');
    });
    fs.writeFileSync("hashIllust.txt", JSON.stringify(hashIllust), function(err) {
        if (err) {
            console.log("Error!");
        }
        console.log('Saved.');
    });
    process.exit();
});

if (fs.existsSync("hashIllust.txt")) {
    var hashJSON = fs.readFileSync("hashIllust.txt", "UTF8");
    hashIllust = JSON.parse(hashJSON);
}

if (fs.existsSync("illustQueue.txt")) {
    var illJSON = fs.readFileSync("illustQueue.txt", "UTF8");
    illustQueue = JSON.parse(illJSON);
} else {
    console.log("先扒用户！");
    process.exit();
}

main();