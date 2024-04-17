// ==PluginsInfo==
// @name         千千音乐
// @site         baidu
// @version      0.0.2
// @author       yhsj
// @icon         https://music.taihe.com/favicon.ico
// @webSite      https://music.taihe.com
// @method       ["searchMusic","playUrl","playListRec","albumRec","songRec","playList","playListType","playListInfo","rankList","rankInfo","artistList","artistType","artistInfo","artistSong","artistAlbum","parsePlayList"]
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

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
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

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: respData["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }
        try {
            const path = respData["data"]["lyric"];
            if (path != null && path !== "") {
                const response = await axios.get(path);
                mySong["lyric"] = response.data;
            }
        } catch (error) {
            console.error('Error:', error);
        }
        mySong["url"] = respData["data"]["path"]


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

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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

//歌单推荐
function playListRec() {
    // 定义查询参数
    const params = {
        timestamp: Date.now(),
        appid: 16073360,
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/index', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["data"].find(function (data) {
            return data["type"] === "tracklist";
        });


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

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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

    console.log(playlist)
    console.log(typeof playlist)

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

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
            pic: `${result["pic"]}@w_200,h_200`,
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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
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

//专辑推荐
function albumRec() {
    // 定义查询参数
    const params = {
        timestamp: Date.now(),
        appid: 16073360,
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/index', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["data"].find(function (data) {
            return data["type"] === "album";
        });


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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                }),
                songCount: element['trackCount'],
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,

        };
        return JSON.stringify(resp);
    });
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

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
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

    console.log(album)
    console.log(typeof album)

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

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
                return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
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
        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

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

// 排行榜详情
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

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
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

//歌手分类
function artistType() {

    const newArray = [
        {
            site: 'baidu',
            id: "artistFristLetter",
            name: '首字母',
            subType: [
                {site: 'baidu', id: "", name: '全部'},
                {site: 'baidu', id: 'A', name: 'A'},
                {site: 'baidu', id: 'B', name: 'B'},
                {site: 'baidu', id: 'C', name: 'C'},
                {site: 'baidu', id: 'D', name: 'D'},
                {site: 'baidu', id: 'E', name: 'E'},
                {site: 'baidu', id: 'F', name: 'F'},
                {site: 'baidu', id: 'G', name: 'G'},
                {site: 'baidu', id: 'H', name: 'H'},
                {site: 'baidu', id: 'I', name: 'I'},
                {site: 'baidu', id: 'J', name: 'J'},
                {site: 'baidu', id: 'K', name: 'K'},
                {site: 'baidu', id: 'L', name: 'L'},
                {site: 'baidu', id: 'M', name: 'M'},
                {site: 'baidu', id: 'N', name: 'N'},
                {site: 'baidu', id: 'O', name: 'O'},
                {site: 'baidu', id: 'P', name: 'P'},
                {site: 'baidu', id: 'Q', name: 'Q'},
                {site: 'baidu', id: 'R', name: 'R'},
                {site: 'baidu', id: 'S', name: 'S'},
                {site: 'baidu', id: 'T', name: 'T'},
                {site: 'baidu', id: 'U', name: 'U'},
                {site: 'baidu', id: 'V', name: 'V'},
                {site: 'baidu', id: 'W', name: 'W'},
                {site: 'baidu', id: 'X', name: 'X'},
                {site: 'baidu', id: 'Y', name: 'Y'},
                {site: 'baidu', id: 'Z', name: 'Z'},
                {site: 'baidu', id: 'other', name: '#'},
            ]
        },
        {
            site: 'baidu',
            id: "artistGender",
            name: '性别',
            subType: [
                {site: 'baidu', id: "", name: '全部'},
                {site: 'baidu', id: '男', name: '男'},
                {site: 'baidu', id: '女', name: '女'},
                {site: 'baidu', id: '组合', name: '组合'},
                {site: 'baidu', id: '乐队', name: '乐队'}]
        },
        {
            site: 'baidu',
            id: "artistRegion",
            name: '地区',
            subType: [
                {site: 'baidu', id: "", name: '全部'},
                {site: 'baidu', id: '内地', name: '内地'},
                {site: 'baidu', id: '港台', name: '港台'},
                {site: 'baidu', id: '欧美', name: '欧美'},
                {site: 'baidu', id: '韩国', name: '韩国'},
                {site: 'baidu', id: '日本', name: '日本'},
                {site: 'baidu', id: '其他', name: '其他'}]
        }];
    const resp = {
        code: 200,
        msg: '操作成功',
        data: newArray
    };
    return JSON.stringify(resp);
}

//根据分类获取歌手
function artistList(type, page = 0, size = 20) {

    const params = JSON.parse(type ?? "{}");

    params["pageNo"] = parseInt(page) + 1
    params["pageSize"] = size
    params["timestamp"] = Date.now()
    params["appid"] = 16073360

    console.log(type)


    params['sign'] = paramsSign(params);
    https://music.91q.com/v1/artist/list?sign=24942010ce9864df0e507f1ec15411f8&pageNo=1&artistFristLetter=A&artistRegion=&artistGender=&pageSize=48&appid=16073360&timestamp=1710912762
        return axios.get('https://api-qianqian.taihe.com/v1/artist/list', {
            params
        }, {
            headers: headers
        }).then(function (data) {

            let respData;

            if (typeof data.data === 'string') {
                respData = JSON.parse(data.data)
            } else {
                respData = data.data
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
                    id: element['artistCode'],
                    pic: element["pic"],
                    name: element['name'],
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

// 歌手详情
function artistInfo(artist, page = 0, size = 20) {

    const myPlaylist = JSON.parse(artist);
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

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
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

// 歌手歌曲
function artistSong(artist, page = 0, size = 20) {

    const myArtist = JSON.parse(artist);
    // 定义查询参数
    const params = {
        artistCode: myArtist["id"],
        pageNo: parseInt(page) + 1,
        pageSize: size,
        timestamp: Date.now(),
        appid: 16073360
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/artist/song', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
                id: element['assetId'],
                pic: `${element["pic"]}@w_200,h_200`,
                title: element['title'],
                subTitle: element["artist"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                vip: element["isVip"],
                artist: element["artist"].map(function (ar) {
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                }),
            };
        });


        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: parseInt(page) === 0,
                last: (parseInt(page) + 1) * parseInt(size) > result["total"],
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

// 歌手专辑
function artistAlbum(artist, page = 0, size = 20) {

    const myArtist = JSON.parse(artist);
    // 定义查询参数
    const params = {
        artistCode: myArtist["id"],
        pageNo: parseInt(page) + 1,
        pageSize: size,
        timestamp: Date.now(),
        appid: 16073360
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/artist/album', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                }),
                desc: element['introduce'],
            };
        });


        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: parseInt(page) === 0,
                last: (parseInt(page) + 1) * parseInt(size) > result["total"],
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

//搜索音乐
function songRec() {
    // 定义查询参数
    const params = {
        timestamp: Date.now(),
        appid: 16073360,
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/index', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["errno"] !== 22000) {
            const resp = {
                code: 500,
                msg: data["errmsg"],
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["data"].find(function (data) {
            return data["type"] === "song";
        });

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
                    return {site: "baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
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
            data: newArray
        };
        return JSON.stringify(resp);
    });
}

// 歌单详情
function parsePlayList(url) {
    console.log(url)
    if (!url.toString().includes("music.91q.com") && !url.toString().includes("music.taihe.com")) {
        return JSON.stringify({code: 500, msg: "暂不支持此链接"});
    }
    console.log(url)

    var id

    let pattern = /[/][\d]+[?]*/g;
    // 使用正则表达式的 exec() 方法来执行匹配
    let matches = url.toString().match(pattern);

    if (matches !== null) {
        id = matches[0].slice(1, -1)
    }

    console.log(url)
    console.log(id)
    //
    // 定义查询参数
    const params = {
        id: id,
        pageNo: 1,
        pageSize: 10,
        timestamp: Date.now(),
        appid: 16073360
    };

    params['sign'] = paramsSign(params);

    return axios.get('https://api-qianqian.taihe.com/v1/tracklist/info', {
        params
    }, {
        headers: headers
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
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
            pic: `${result["pic"]}@w_200,h_200`,
            title: result['title'],
            subTitle: result['desc'],
            desc: result['desc'],
            songCount: result['trackCount'],
        }

        const resp = {
            code: 200,
            msg: '操作成功',
            data: newPlaylist,
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
