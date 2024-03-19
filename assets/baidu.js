// ==PluginsInfo==
// @name         千千音乐
// @site         baidu
// @version      0.0.2
// @author       yhsj
// @icon         https://music.taihe.com/favicon.ico
// @webSite      https://music.taihe.com
// @method       ["searchMusic","playUrl","playList","playListType","playListInfo"]
// ==/PluginsInfo==


const headers = {
    "app-version": "v8.3.0.4",
    "from": "android",
    "user-agent": "Mozilla/5.0 (Linux; U; Android 11.0.0; zh-cn; MI Build/OPR1.170623.032) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
}

//搜索音乐
function searchMusic(key, page = 0, size = 20) {
    // 定义查询参数
    const params = {
        pageNo: parseInt(page) + 1,
        pageSize: size,
        timestamp: Date.now(),
        type: 1,
        word: key,
        appid: 16073360,
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/search', {
        params
    }, {
        headers: headers
    }).then(function (data) {
        let respData;

        if (typeof data["data"] === 'string') {
            respData = JSON.parse(data["data"].replaceAll("\n", ""))
        } else {
            respData = data["data"]
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }

        const result = respData["data"]

        const newArray = result["typeTrack"].map(function (element) {
            return {
                site: 'baidu',
                id: element['assetId'],
                pic: `${element["pic"]}@w_200,h_200`,
                title: element['title'],
                subTitle: element["artist"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                vip: element["isVip"],
                artist: element["artist"].map(function (ar) {
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}@w_200,h_200`}
                }),
                album: {
                    site: "baidu",
                    id: element["albumAssetCode"],
                    title: element["albumTitle"],
                    pic: `${element["pic"]}@w_200,h_200`,
                },
                lyric: element["lyric"],
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: page === 0,
                last: result["haveMore"] !== 1,
                page: parseInt(page) + 1,
                size: parseInt(size),
                number: newArray.length,
                totalPages: Math.floor(result["total"] / parseInt(size)),
                totalSize: result["total"]
            }
        };
        return JSON.stringify(resp);
    });
}

//获取播放地址
function playUrl(song) {
    var mySong = JSON.parse(song)
    // 定义查询参数
    const params = {
        TSID: mySong["id"],
        timestamp: Date.now(),
        appid: 16073360,
        rate: mySong['rate'] ?? 64,
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/song/tracklink', {
        params
    }, {
        headers: headers
    }).then(async function (data) {

        console.log(JSON.stringify(data))

        if (data["data"]["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["data"]["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }
        try {
            const path = data["data"]["data"]["lyric"];
            if (path != null && path !== "") {
                const response = await axios.get(path);
                mySong["lyric"] = response.data;
            }
        } catch (error) {
            console.error('Error:', error);
        }
        mySong["url"] = data["data"]["data"]["path"]


        const resp = {
            code: 200,
            msg: '操作成功',
            data: mySong
        };
        return JSON.stringify(resp);
    });
}

//歌单分类
function playListType() {
    // 定义查询参数
    const params = {
        timestamp: Date.now(),
        appid: 16073360,
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/tracklist/category', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        const respData = data["data"]

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }

        const result = respData["data"]

        const newArray = result.map(function (element) {
            return {
                site: 'baidu',
                id: element['id'],
                name: element['categoryName'],
                subType: element['subCate'].map(function (element) {
                    return {
                        site: 'baidu',
                        id: element['id'],
                        name: element['categoryName'],
                    };
                })
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray
        };
        return JSON.stringify(resp);
    });
}

//根据分类获取歌单
function playList(type, page = 0, size = 20) {
    // 定义查询参数
    const params = {
        pageNo: parseInt(page) + 1,
        pageSize: size,

        timestamp: Date.now(),
        appid: 16073360,
    };
    console.log(type)
    if (type !== "null") {
        params["subCateId"] = type
    }

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/tracklist/list', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData
        if (typeof data["data"] === "object") {
            respData = data["data"]
        } else {
            let str = data["data"].replaceAll("。\"\",", "。\",").replaceAll("\n", "")

            // 正则表达式来匹配一些包含在文字中的引号
            let pattern = /"[\u4e00-\u9fa5]+"。/g;
            let pattern2 = /""[\u4e00-\u9fa5]+"[\u4e00-\u9fa5]+/g;
            let pattern3 = /"[\u4e00-\u9fa5]+"[^,}\]]/g;

            // 使用正则表达式的 exec() 方法来执行匹配
            let matches = str.match(pattern);
            let matches2 = str.match(pattern2);
            let matches3 = str.match(pattern3);
            if (matches !== null) {
                matches.forEach(function (element) {
                    str = str.replaceAll(element, element.replaceAll("\"", "”"))
                });
            }
            if (matches2 !== null) {
                matches2.forEach(function (element) {
                    str = str.replaceAll(element.substring(1), element.substring(1).replaceAll("\"", "”"))
                });
            }
            if (matches3 !== null) {
                matches3.forEach(function (element) {
                    str = str.replaceAll(element, element.replaceAll("\"", "”"))
                });
            }
            console.log(str)

            respData = JSON.parse(str)
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["data"]


        const newArray = result["result"].map(function (element) {
            return {
                site: 'baidu',
                id: element['id'],
                pic: `${element["pic"]}@w_200,h_200`,
                title: element['title'],
                subTitle: element['desc'],
                desc: element['desc'],
                songCount: element['trackCount'],
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: page === 0,
                last: result["haveMore"] !== 1,
                page: parseInt(page) + 1,
                size: parseInt(size),
                number: newArray.length,
                totalPages: Math.floor(result["total"] / parseInt(size)),
                totalSize: result["total"]
            }
        };
        return JSON.stringify(resp);
    });
}

// 歌单详情
function playListInfo(playlist, page = 0, size = 20) {

    const myPlaylist = JSON.parse(playlist);
    // 定义查询参数
    const params = {
        id: myPlaylist["id"],
        pageNo: parseInt(page) + 1,
        pageSize: size,
        timestamp: Date.now(),
        appid: 16073360
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/tracklist/info', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData
        if (typeof data["data"] === "object") {
            respData = data["data"]
        } else {
            let str = data["data"].replaceAll("。\"\",", "。\",").replaceAll("\n", "")

            // 正则表达式来匹配一些包含在文字中的引号
            let pattern = /"[\u4e00-\u9fa5]+"。/g;
            let pattern2 = /""[\u4e00-\u9fa5]+"[\u4e00-\u9fa5]+/g;
            let pattern3 = /"[\u4e00-\u9fa5]+"[^,}\]]/g;

            // 使用正则表达式的 exec() 方法来执行匹配
            let matches = str.match(pattern);
            let matches2 = str.match(pattern2);
            let matches3 = str.match(pattern3);
            if (matches !== null) {
                matches.forEach(function (element) {
                    str = str.replaceAll(element, element.replaceAll("\"", "”"))
                });
            }
            if (matches2 !== null) {
                matches2.forEach(function (element) {
                    str = str.replaceAll(element.substring(1), element.substring(1).replaceAll("\"", "”"))
                });
            }
            if (matches3 !== null) {
                matches3.forEach(function (element) {
                    str = str.replaceAll(element, element.replaceAll("\"", "”"))
                });
            }
            console.log(str)

            respData = JSON.parse(str)
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["data"]

        const newPlaylist = {
            site: 'baidu',
            id: result['id'],
            title: result['title'],
            subTitle: result['desc'],
            desc: result['desc'],
            songCount: result['trackCount'],
        }


        const newArray = result["trackList"].map(function (element) {
            return {
                site: 'baidu',
                id: element['assetId'],
                pic: `${element["pic"]}@w_200,h_200`,
                title: element['title'],
                subTitle: element["artist"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                vip: element["isVip"],
                artist: element["artist"].map(function (ar) {
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}@w_200,h_200`}
                }),
                album: {
                    site: "baidu",
                    id: element["albumAssetCode"],
                    title: element["albumTitle"],
                    pic: `${element["pic"]}@w_200,h_200`,
                },
                lyric: element["lyric"],
            };
        });

        newPlaylist['songs'] = newArray

        const resp = {
            code: 200,
            msg: '操作成功',
            data: newPlaylist,
            page: {
                first: page === 0,
                last: result["haveMore"] !== 1,
                page: parseInt(page) + 1,
                size: parseInt(size),
                number: newArray.length,
                totalPages: Math.floor(result["trackCount"] / parseInt(size)),
                totalSize: result["trackCount"]
            }
        };
        return JSON.stringify(resp);
    });
}


//专辑分类
function albumType() {
    const resp = {
        code: 200,
        msg: '操作成功',
        data: []
    };
    return JSON.stringify(resp);
}

//根据分类获取专辑
function albumList(type, page = 0, size = 20) {
    // 定义查询参数
    const params = {
        pageNo: parseInt(page) + 1,
        pageSize: size,

        timestamp: Date.now(),
        appid: 16073360,
    };
    console.log(type)


    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/album/list', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData
        if (typeof data["data"] === "object") {
            respData = data["data"]
        } else {
            let str = data["data"].replaceAll("。\"\",", "。\",").replaceAll("\n", "")

            // 正则表达式来匹配一些包含在文字中的引号
            let pattern = /"[^:,{\[]"[\u4e00-\u9fa5]+"[^,}\]]/g;

            // 使用正则表达式的 exec() 方法来执行匹配
            let matches = str.match(pattern);

            if (matches !== null) {
                matches.forEach(function (element) {
                    str = str.replaceAll(element, element.replaceAll("\"", "”"))
                });
            }
            console.log(str)

            respData = JSON.parse(str)
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["data"]


        const newArray = result["result"].map(function (element) {
            return {
                site: 'baidu',
                id: element['albumAssetCode'],
                pic: `${element["pic"]}@w_200,h_200`,
                title: element['title'],
                subTitle: element["artist"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                artist: element["artist"].map(function (ar) {
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}@w_200,h_200`}
                }),
                songCount: element['trackCount'],
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: page === 0,
                last: result["haveMore"] !== 1,
                page: parseInt(page) + 1,
                size: parseInt(size),
                number: newArray.length,
                totalPages: Math.floor(result["total"] / parseInt(size)),
                totalSize: result["total"]
            }
        };
        return JSON.stringify(resp);
    });
}

// 专辑详情
function albumInfo(album, page = 0, size = 20) {

    const myAlbum = JSON.parse(album);
    // 定义查询参数
    const params = {
        albumAssetCode: myAlbum["id"],
        timestamp: Date.now(),
        appid: 16073360
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/album/info', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData
        if (typeof data["data"] === "object") {
            respData = data["data"]
        } else {
            let str = data["data"].replaceAll("。\"\",", "。\",").replaceAll("\n", "")

            // 正则表达式来匹配一些包含在文字中的引号
            let pattern = /"[^:,{\[]"[\u4e00-\u9fa5]+"[^,}\]]/g;

            // 使用正则表达式的 exec() 方法来执行匹配
            let matches = str.match(pattern);

            if (matches !== null) {
                matches.forEach(function (element) {
                    str = str.replaceAll(element, element.replaceAll("\"", "”"))
                });
            }

            console.log(str)

            respData = JSON.parse(str)
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["data"]

        const newAlbum = {
            site: 'baidu',
            id: result['albumAssetCode'],
            pic: `${result["pic"]}@w_200,h_200`,
            title: result['title'],
            subTitle: result["artist"].map(function (ar) {
                return ar["name"]
            }).join(","),
            artist: result["artist"].map(function (ar) {
                return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}@w_200,h_200`}
            }),
            desc: result["introduce"],

        }
        const newArray = result["trackList"].map(function (element) {
            return {
                site: 'baidu',
                id: element['assetId'],
                pic: `${result["pic"]}@w_200,h_200`,
                title: element['title'],
                subTitle: result["artist"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                vip: element["isVip"],
                artist: result["artist"].map(function (ar) {
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}@w_200,h_200`}
                }),
            };
        });

        newAlbum['songs'] = newArray
        newAlbum['songCount'] = newArray.length

        const resp = {
            code: 200,
            msg: '操作成功',
            data: newAlbum,
            page: {
                first: page === 0,
                last: true,
                page: parseInt(page) + 1,
                size: parseInt(size),
                number: newArray.length,
                totalPages: 1,
                totalSize: newArray.length
            }
        };
        return JSON.stringify(resp);
    });
}


//排行榜
function rankList() {
    // 定义查询参数
    const params = {
        timestamp: Date.now(),
        appid: 16073360,
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/bd/category', {
        params
    }, {
        headers: headers
    }).then(function (data) {
        console.log(data)
        let respData
        if (typeof data["data"] === "object") {
            respData = data["data"]
        } else {
            let str = data["data"].replaceAll("。\"\",", "。\",").replaceAll("\n", "")

            let pattern = /"[^:,{\[]"[\u4e00-\u9fa5]+"[^,}\]]/g;

            // 使用正则表达式的 exec() 方法来执行匹配
            let matches = str.match(pattern);

            if (matches !== null) {
                matches.forEach(function (element) {
                    str = str.replaceAll(element, element.replaceAll("\"", "”"))
                });
            }


            respData = JSON.parse(str)
        }

        console.log(JSON.stringify(respData))

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const newArray = respData["data"].map(function (element) {
            return {
                site: 'baidu',
                id: element['bdid'],
                pic: `${element["pic"]}@w_200,h_200`,
                title: element['title'],
            };
        });
        const type = [
            {
                site: 'baidu',
                title: '官方榜',
                rankList: newArray,
            }
        ]


        const resp = {
            code: 200,
            msg: '操作成功',
            data: type
        };
        return JSON.stringify(resp);
    });
}

// 专辑详情
function rankInfo(rank, page = 0, size = 20) {

    const myRank = JSON.parse(rank);
    // 定义查询参数
    const params = {
        bdid: myRank["id"],
        pageNo: parseInt(page) + 1,
        pageSize: size,
        timestamp: Date.now(),
        appid: 16073360
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/bd/list', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData
        if (typeof data["data"] === "object") {
            respData = data["data"]
        } else {
            let str = data["data"].replaceAll("。\"\",", "。\",").replaceAll("\n", "")

            // 正则表达式来匹配一些包含在文字中的引号
            let pattern = /"[^:,{\[]"[\u4e00-\u9fa5]+"[^,}\]]/g;

            // 使用正则表达式的 exec() 方法来执行匹配
            let matches = str.match(pattern);

            if (matches !== null) {
                matches.forEach(function (element) {
                    str = str.replaceAll(element, element.replaceAll("\"", "”"))
                });
            }
            console.log(str)
            respData = JSON.parse(str)
        }
        console.log(JSON.stringify(respData))
        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["data"]

        const newAlbum = {
            site: 'baidu',
            id: result['bdid'],
            pic: `${myRank["pic"]}`,
            title: result['title'],
            songCount: result['total']
        }
        const newArray = result["result"].map(function (element) {
            return {
                site: 'baidu',
                id: element['assetId'],
                pic: `${element["pic"]}@w_200,h_200`,
                title: element['title'],
                subTitle: element["artist"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                vip: element["isVip"],
                artist: element["artist"].map(function (ar) {
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}@w_200,h_200`}
                }),
            };
        });

        newAlbum['songs'] = newArray

        const resp = {
            code: 200,
            msg: '操作成功',
            data: newAlbum,
            page: {
                first: parseInt(page) === 0,
                last: result["haveMore"] !== 1,
                page: parseInt(page) + 1,
                size: parseInt(size),
                number: newArray.length,
                totalPages: Math.floor(result["total"] / parseInt(size)),
                totalSize: result["total"]
            }
        };
        return JSON.stringify(resp);
    });
}


function paramsSign(params) {

    const paramsString = Object.entries(params)
        .map(([key, value]) => `${key}=${value}`)
        .sort()
        .join('&');
    const signStr = `${paramsString.toString()}0b50b02fd0d73a9c4c8c3a781c30845f`;

    console.log(signStr)

    return CryptoJS.MD5(signStr).toString();
}
