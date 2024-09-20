// ==MixMusicPlugin==
// @name         MyFreeMp3
// @site         MyFreeMp3
// @package      xyz.yhsj.myfreemp3
// @version      0.0.1
// @versionCode  1
// @author       永恒瞬间
// @icon         https://new.myfreemp3juices.cc/favicon-32x32.png
// @webSite      https://new.myfreemp3juices.cc
// @updateUrl    https://new.myfreemp3juices.cc
// @desc         官方插件
// ==/MixMusicPlugin==

const music = {
    search: {
        music: function searchMusic(key, page = 0, size = 20) {
            return axios.post('https://new.myfreemp3juices.cc/api/api_search.php', {
                q: key,
                page: page
            }, {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                }
            }).then(function (data) {
                try {
                    const result = JSON.parse(data.data.trim().slice(1, -2));
                    if (result["response"] == null || result["response"] === []) {
                        return {
                            code: 200,
                            msg: '操作成功',
                            data: []
                        };
                    }
                    const list = result["response"].filter(item => item !== "apple");
                    const newArray = list.map(function (element) {
                        return {
                            package: 'xyz.yhsj.myfreemp3',
                            id: element['id'],
                            title: element['title'],
                            subTitle: element['artist'],
                            pic: 'https://new.myfreemp3juices.cc/favicon-32x32.png',
                            artist: [{
                                package: 'xyz.yhsj.myfreemp3',
                                title: element['artist']
                            }],
                            url: element['url']
                        };
                    });
                    return {
                        code: 200,
                        msg: '操作成功',
                        data: newArray,
                        page: {
                            first: page === 0,
                            last: newArray.length < 29,
                            page: parseInt(page) + 1,
                            size: 29,
                            number: newArray.length,
                            totalPages: newArray.length,
                            totalSize: newArray.length
                        }
                    };
                } catch (e) {
                    return {
                        code: 500,
                        msg: '解析失败'
                    };
                }

            });
        }
    },
    url: {
        playUrl: function playUrl(song) {
            return {
                code: 200,
                msg: '操作成功',
                data: song
            };
        }
    }
}


