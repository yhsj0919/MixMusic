// ==PluginsInfo==
// @name         MyFreeMp3
// @site         MyFreeMp3
// @version      0.0.1
// @author       yhsj
// @icon         https://new.myfreemp3juices.cc/favicon-32x32.png
// @webSite      https://new.myfreemp3juices.cc
// @method       ["searchMusic","playUrl"]
// ==/PluginsInfo==


function searchMusic(key, page = 0, size = 20) {
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
                const resp = {
                    code: 200,
                    msg: '操作成功',
                    data: []
                };
                return JSON.stringify(resp);
            }
            const list = result["response"].filter(item => item !== "apple");
            const newArray = list.map(function (element) {
                return {
                    site: 'MyFreeMp3',
                    id: element['id'],
                    title: element['title'],
                    subTitle: element['artist'],
                    pic: 'https://new.myfreemp3juices.cc/favicon-32x32.png',
                    artist: [{
                        site: 'MyFreeMp3',
                        name: element['artist']
                    }],
                    url: element['url']
                };
            });
            const resp = {
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
            return JSON.stringify(resp);
        } catch (e) {
            const resp = {
                code: 500,
                msg: '解析失败'
            };
            return JSON.stringify(resp);
        }

    });
}

function playUrl(song) {
    console.log(song)
    const resp = {
        code: 200,
        msg: '操作成功',
        data: JSON.parse(song)
    };

    console.log(resp)
    return JSON.stringify(resp);
}