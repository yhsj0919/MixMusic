// ==PluginsInfo==
// @name         QQ音乐
// @site         qq
// @version      0.0.1
// @author       yhsj
// @icon         https://y.qq.com/favicon.ico
// @webSite      https://y.qq.com
// @method       ["searchMusic","playUrl","playList","playListType","albumType","albumList"]
// ==/PluginsInfo==

// ,"playListRec","albumRec","songRec","playListInfo","rankList","rankInfo","artistList","artistType","artistInfo","artistSong","artistAlbum",parsePlayList"
const headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0",
    "Cookie": "",
    "Referer": "https://y.qq.com/",
}

let _uid = ''

function getUid() {
    if (_uid) {
        return _uid
    }
    if (!_uid) {
        const t = (new Date()).getUTCMilliseconds()
        _uid = '' + Math.round(2147483647 * Math.random()) * t % 1e10
    }
    return _uid
}


//搜索音乐
async function searchMusic(key, page = 0, size = 20) {
    // 定义查询参数
    const params = {
        data: JSON.stringify({
            comm: {
                format: "json",
                inCharset: "utf-8",
                outCharset: "utf-8",
                needNewCode: 1,
                ct: 23,
                cv: 0
            },
            req: {
                method: "DoSearchForQQMusicDesktop",
                module: "music.search.SearchCgiService",
                param: {
                    searchid: `${Math.floor(Math.random() * 10000000000000000)}`,
                    search_type: 0,
                    query: key,
                    page_num: parseInt(page) + 1,
                    num_per_page: size
                }
            }
        })
    }

    return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
        headers: headers,
        params: params,
    }).then(function (data) {

        let respData;
        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }
        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
                data: null
            };
            return JSON.stringify(resp);
        }


        const newArray = respData["req"]["data"]["body"]["song"]["list"].map(function (element) {
            return {
                site: 'qq',
                id: {
                    id: element["id"],
                    mid: element["mid"],
                    mediaId: element["file"]["media_mid"]
                },
                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                title: element['name'],
                subTitle: element["singer"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                vip: element["pay"]["pay_play"],
                artist: element["singer"].map(function (ar) {
                    return {
                        site: "qq",
                        id: ar["mid"],
                        name: ar["name"],
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                    }
                }),
                album: {
                    site: "qq",
                    id: element["album"]["mid"],
                    title: element["album"]["title"],
                    pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                },
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: parseInt(page) === 0,
                last: respData["req"]["data"]["meta"]["nextpage"] === -1,
                page: respData["req"]["data"]["meta"]["curpage"],
                size: respData["req"]["data"]["meta"]["perpage"],
                number: newArray.length,
                totalPages: Math.floor(respData["req"]["data"]["meta"]["sum"] / respData["req"]["data"]["meta"]["perpage"]),
                totalSize: respData["req"]["data"]["meta"]["sum"]
            }
        };
        return JSON.stringify(resp);
    });
}

//获取播放地址
async function playUrl(song) {
    const mySong = JSON.parse(song);

    try {
        const lrcParams = {
            nobase64: 1,
            format: 'json',
            songmid: mySong["id"]["mid"],
        }
        console.log(JSON.stringify(lrcParams))
        const response = await axios.get("https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg", {
            headers: {Referer: 'https://y.qq.com/'},
            params: lrcParams
        });
        mySong["lyric"] = response.data["lyric"];

    } catch (error) {
        console.error('Error:', error);
    }

    // 定义查询参数
    const params = {
        data: JSON.stringify({
            comm: {
                format: "json",
                ct: 24,
                cv: 0,
                uin: "0",
            },
            req: {
                method: "CgiGetVkey",
                module: "vkey.GetVkeyServer",
                param: {
                    guid: getUid(),
                    songmid: [`${mySong["id"]["mid"]}`],
                    songtype: [0],
                    uin: "0",
                    loginflag: 1,
                    platform: "20",
                }
            }
        })
    }
    console.log(params)

    return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
        headers: headers,
        params: params
    }).then(async function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
                data: null
            };
            return JSON.stringify(resp);
        }

        console.log(JSON.stringify(respData))

        try {
            const urls = respData["req"]["data"]["midurlinfo"].filter(item => item["purl"] !== "");
            const sip = respData["req"]["data"]["sip"]
            if (urls.length !== 0 && sip.length !== 0) {
                const url = `${sip[0]}${urls[0]["purl"]}`
                mySong["url"] = url;
            }

        } catch (error) {
            console.error('Error:', error);
        }
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
        data: JSON.stringify({
            comm: {
                format: "json",
                g_tk: 5381,
                ct: 20,
                cv: 1807,
                uin: "0",
                platform: "wk_v17",
            },
            allTag: {
                method: "GetAllTag",
                module: "music.playlist.PlaylistSquare",
                param: {}
            }
        })
    }

    return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
                data: null
            };
            return JSON.stringify(resp);
        }

        const result = respData["allTag"]["data"]["v_group"]

        const newArray = result.map(function (element) {
            return {
                site: 'qq',
                id: element['group_id'],
                name: element['group_name'],
                subType: element['v_item'].map(function (element) {
                    return {
                        site: 'qq',
                        id: element['id'],
                        name: element['name'],
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
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
        data: JSON.stringify({
            comm: {ct: 20, cv: 1807, uin: "0"},
            playlist: {
                module: "playlist.PlayListCategoryServer",
                method: "get_category_content",
                param: {
                    last_id: "",
                    size: parseInt(size),
                    page: parseInt(page),
                    caller: "0",
                    category_id: type === "null" ? 3317 : parseInt(type),
                },
            }
        })
    }

    return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
        headers: headers,
        params: params
    }).then(function (data) {


        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
                data: null
            };
            return JSON.stringify(resp);
        }

        const result = respData["playlist"]["data"]["content"]

        const newArray = result["v_item"].map(function (element) {

            return {
                site: 'qq',
                id: element["basic"]['tid'],
                pic: element["basic"]["cover"]["default_url"],
                title: element["basic"]["title"],
                subTitle: element["basic"]["desc"],
                desc: element["basic"]["desc"],
                songCount: element["basic"]["song_cnt"],
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: page === 0,
                last: parseInt(size) * (parseInt(page) + 1) > parseInt(result["total_cnt"]),
                page: parseInt(page) + 1,
                size: parseInt(size),
                number: newArray.length,
                totalPages: Math.floor(result["total_cnt"] / parseInt(size)),
                totalSize: result["total_cnt"]
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
        data: JSON.stringify({
            comm: {
                g_tk: 5381,
                uin: 0,
                format: "json",
                ct: 20,
                cv: 1807,
                platform: "wk_v17",
            },
            playlist: {
                module: "music.srfDissInfo.aiDissInfo",
                method: "uniform_get_Dissinfo",
                param: {
                    disstid: myPlaylist["id"],
                    userinfo: 1,
                    tag: 1,
                    orderlist: 1,
                    song_begin: parseInt(page) * parseInt(size),
                    song_num: parseInt(size),
                    onlysonglist: 0,
                    enc_host_uin: ""
                }
            }
        })
    }

    console.log(JSON.stringify(params))


    return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
        headers: headers,
        params: params
    }).then(function (data) {
        console.log(JSON.stringify(data))
        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
                data: null
            };
            return JSON.stringify(resp);
        }


        const result = respData["playlist"]["data"]

        const newPlaylist = {
            site: 'qq',
            id: result["dirinfo"]['id'],
            pic: result["dirinfo"]["picurl"],
            title: result["dirinfo"]['title'],
            subTitle: result["dirinfo"]['desc'],
            desc: result["dirinfo"]['desc'],
            songCount: result["dirinfo"]['songnum'],
        }

        console.log(result["dirinfo"]['songnum'])

        const newArray = result["songlist"].map(function (element) {
            return {
                site: 'qq',
                id: {
                    id: element["id"],
                    mid: element["mid"],
                    mediaId: element["file"]["media_mid"]
                },
                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                title: element['name'],
                subTitle: element["singer"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                vip: element["pay"]["pay_play"],
                artist: element["singer"].map(function (ar) {
                    return {
                        site: "qq",
                        id: ar["mid"],
                        name: ar["name"],
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                    }
                }),
                album: {
                    site: "qq",
                    id: element["album"]["mid"],
                    title: element["album"]["title"],
                    pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                },
            };
        });

        newPlaylist['songs'] = newArray

        const resp = {
            code: 200,
            msg: '操作成功',
            data: newPlaylist,
            page: {
                first: page === 0,
                last: parseInt(page) * parseInt(size) >= parseInt(result["dirinfo"]['songnum']),
                page: parseInt(page) + 1,
                size: parseInt(size),
                number: newArray.length,
                totalPages: 1,
                totalSize: result["dirinfo"]['songnum']
            }
        };
        return JSON.stringify(resp);
    });
}

//专辑分类
function albumType() {
    // 定义查询参数
    const params = {
        data: JSON.stringify({
            comm: {
                format: "json",
                g_tk: 5381,
                ct: 20,
                cv: 1807,
                uin: "0",
                platform: "wk_v17",
            },
            allTag: {
                module: "newalbum.NewAlbumServer",
                method: "get_new_album_area",
                param: {}
            }
        })
    }

    return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
                data: null
            };
            return JSON.stringify(resp);
        }

        const result = respData["allTag"]["data"]["area"]

        const newArray = [{
            site: 'qq',
            id: null,
            name: "区域",
            subType: result.map(function (element) {
                return {
                    site: 'qq',
                    id: element['id'],
                    name: element['name'],
                };
            })
        }]
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray
        };
        return JSON.stringify(resp);
    });
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
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
        data: JSON.stringify({
            comm: {ct: 20, cv: 1807, uin: "0"},
            album: {
                module: "newalbum.NewAlbumServer",
                method: "get_new_album_info",
                param: {
                    last_id: "",
                    start: parseInt(size) * parseInt(page),
                    num: parseInt(size),
                    area: type === "null" ? 1 : parseInt(type),
                },
            }
        })
    }

    return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
        headers: headers,
        params: params
    }).then(function (data) {
        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
                data: null
            };
            return JSON.stringify(resp);
        }

        const result = respData["album"]["data"]

        const newArray = result["albums"].map(function (element) {
            return {
                site: 'qq',
                id: element['mid'],
                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["mid"]}.jpg`,
                title: element['name'],
                subTitle: element["singers"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                artist: element["singers"].map(function (ar) {
                    return {site: "qq", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                }),
            };
        });
        const resp = {
            code: 200,
            msg: '操作成功',
            data: newArray,
            page: {
                first: page === 0,
                last: parseInt(size) * (parseInt(page) + 1) >= parseInt(result["total"]),
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
        data: JSON.stringify({
            comm: {ct: 20, cv: 1807, uin: "0"},
            //该歌手其他专辑
            otherAlbum: {
                module: "music.musichallAlbum.OtherAlbumList",
                method: "OtherAlbumList",
                param: {"albumMid": myAlbum["id"], "order": 0, "num": 6}
            },
            //专辑信息
            albumInfo: {
                module: "music.musichallAlbum.AlbumInfoServer",
                method: "GetAlbumDetail",
                param: {albumMid: myAlbum["id"]}
            },
            //专辑歌曲
            albumSong: {
                module: "music.musichallAlbum.AlbumSongList",
                method: "GetAlbumSongList",
                param: {albumMid: myAlbum["id"], begin: parseInt(page) * parseInt(size), num: parseInt(size), order: 2}
            },
            //是否收藏？
            collect: {
                module: "music.musicasset.AlbumFavRead",
                method: "IsAlbumFan",
                param: {
                    v_albumMid: [myAlbum["albumMid"]]
                }
            },
        })
    }

    return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
                data: null
            };
            return JSON.stringify(resp);
        }


        const info = respData["albumInfo"]["data"]
        const result = respData["albumSong"]["data"]

        const newAlbum = {
            site: 'qq',
            id: info["basicInfo"]["albumMid"],
            pic: `https://y.qq.com/music/photo_new/T002R300x300M000${info["basicInfo"]["albumMid"]}.jpg`,
            title: info["basicInfo"]["albumName"],
            subTitle: info["singer"]["singerList"].map(function (ar) {
                return ar["name"]
            }).join(","),
            desc: info["basicInfo"]["desc"],
            publishDate: info["basicInfo"]["publishDate"],
            songCount: result["totalNum"],

            artist: info["singer"]["singerList"].map(function (ar) {
                return {
                    site: "qq",
                    id: ar["mid"],
                    name: ar["name"],
                    pic: `https://y.qq.com/music/photo_new/T001R300x300M000${ar["mid"]}.jpg`
                }
            }),

        }
        const newArray = result["songList"].map(function (element) {
            return {
                site: 'qq',
                id: {
                    id: element["songInfo"]["id"],
                    mid: element["songInfo"]["mid"],
                    mediaId: element["songInfo"]["file"]["media_mid"]
                },
                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["songInfo"]["album"]["mid"]}.jpg`,
                title: element["songInfo"]['title'],
                subTitle: element["songInfo"]["singer"].map(function (ar) {
                    return ar["name"]
                }).join(","),
                vip: element["songInfo"]["pay"]["pay_play"],
                artist: element["songInfo"]["singer"].map(function (ar) {
                    return {
                        site: "qq",
                        id: ar["mid"],
                        name: ar["name"],
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                    }
                }),
                album: {
                    site: "qq",
                    id: element["songInfo"]["album"]["mid"],
                    title: element["songInfo"]["album"]["title"],
                    pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["songInfo"]["album"]["mid"]}.jpg`,
                },
            };
        });

        newAlbum['songs'] = newArray

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
        headers: headers,
        params: params
    }).then(function (data) {
        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }
        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }
        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
        headers: headers,
        params: params
    }).then(function (data) {

        let respData;

        if (typeof data.data === 'string') {
            respData = JSON.parse(data.data)
        } else {
            respData = data.data
        }

        if (respData["code"] !== 0) {
            const resp = {
                code: 500,
                msg: '请求失败',
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
