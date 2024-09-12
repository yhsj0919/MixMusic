// ==PluginsInfo==
// @name         ShyBotQQ
// @site         ShyBotQQ
// @version      0.0.1
// @author       yhsj
// @icon         https://shybot.top/favicon.ico
// @webSite      https://shybot.top
// @method       ["searchMusic","playUrl"]
// ==/PluginsInfo==

// ==MixMusicPlugin==
// @name         ShyBotQQ
// @site         qq
// @package      xyz.yhsj.shybotqq
// @version      0.0.1
// @versionCode  1
// @author       永恒瞬间
// @icon         https://shybot.top/favicon.ico
// @webSite      https://shybot.top
// @updateUrl    https://shybot.top
// @desc         官方插件
// ==/MixMusicPlugin==


const headers = {
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0",
}

const music = {
    search: {
        music: function searchMusic(key, page = 0, size = 20) {
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
                const newArray = result.map(function (element) {

                    return {
                        package: 'xyz.yhsj.shybotqq',
                        id: {
                            id: element["id"],
                            mid: element["mid"],
                            mediaId: element["media_mid"]
                        },
                        pic: element["pic"] + "&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d",
                        title: element['name'],
                        subTitle: element['singer'],
                        vip: 0,
                        artist: [{
                            package: 'xyz.yhsj.shybotqq',
                            id: '',
                            name: element['singer'],
                        }],
                        album: {
                            package: 'xyz.yhsj.shybotqq',
                            id: element["album_mid"],
                            title: element["album"],
                            pic: element["pic"] + "&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d",
                        },
                        lyric: element["url_lrc"] + "&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d",
                        url: element["url"] + "&ShyToken=9171f7b983fdcf7e3a1de35cf1f3ef514ffaf7a37cbd6673347c257d",
                    };
                });
                return {
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
            });
        }
    },

    url: {
        playUrl: async function playUrl(song) {
            const mySong = JSON.parse(song);
            try {
                const path = mySong["lyric"];
                if (path != null && path !== "") {
                    const response = await axios.get(path);
                    mySong["lyric"] = response.data["lyric"];
                }
            } catch (error) {
                console.error('Error:', error);
            }


            return {
                code: 200,
                msg: '操作成功',
                data: mySong
            };
        }
    }
}





