// ==PluginsInfo==
// @name         ShyBotQQ
// @site         ShyBotQQ
// @version      0.0.1
// @author       yhsj
// @icon         https://shybot.top/favicon.ico
// @webSite      https://shybot.top
// @method       ["searchMusic","playUrl"]
// ==/PluginsInfo==


const headers = {
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0",
}

function searchMusic(key, page = 0, size = 20) {
    // 定义查询参数
    //https://shybot.top/api/?name=%E5%91%A8%E6%9D%B0%E4%BC%A6&type=QQ&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d&page=3
    const params = {
        page: parseInt(page) + 1,
        type: 'QQ',
        ShyToken: '9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d',
        name: key,
    };

    return axios.get('https://shybot.top/api', {
        headers: headers,
        params: params
    }).then(function (data) {

        const result = data["data"]

        console.log(JSON.stringify(result))

        const newArray = result.map(function (element) {

            return {
                site: 'ShyBotQQ',
                id: element['id'],
                pic: element["pic"] + "&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d",
                title: element['name'],
                subTitle: element['singer'],
                vip: 0,
                artist: [{
                    site: 'ShyBotQQ',
                    id: '',
                    name: element['singer'],
                }],
                album: {
                    site: "ShyBotQQ",
                    id: '',
                    title: element["album"],
                    pic: element["pic"] + "&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d",
                },
                lyric: element["url_lrc"] + "&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d",
                url: element["url"] + "&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d",
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: page === 0,
                last: newArray.length < 10,
                page: parseInt(page) + 1,
                size: 10,
                number: newArray.length,
                totalPages: newArray.length,
                totalSize: newArray.length
            }
        };
        return JSON.stringify(resp);
    });
}

async function playUrl(song) {
    console.log(song)
    var mySong = JSON.parse(song)

    try {
        const path = mySong["lyric"];
        if (path != null && path !== "") {
            const response = await axios.get(path);
            mySong["lyric"] = response.data;
        }
    } catch (error) {
        console.error('Error:', error);
    }


    const resp = {
        code: 200,
        msg: '操作成功',
        data: mySong
    };

    console.log(resp)
    return JSON.stringify(resp);
}
