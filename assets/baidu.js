// ==MixMusicPlugin==
// @name         千千音乐
// @site         baidu
// @package      xyz.yhsj.baidu
// @version      0.0.1
// @versionCode  1
// @author       永恒瞬间
// @icon         https://music.taihe.com/favicon.ico
// @webSite      https://music.taihe.com
// @updateUrl    https://music.taihe.com
// @desc         官方插件
// ==/MixMusicPlugin==


const headers = {
    "app-version": "v8.3.0.4",
    "from": "android",
    "user-agent": "Mozilla/5.0 (Linux; U; Android 11.0.0; zh-cn; MI Build/OPR1.170623.032) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
}
const music = {
    search: {
        music: async function (key, page = 0, size = 20) {
            const params = {
                pageNo: parseInt(page) + 1,
                pageSize: size,
                timestamp: Date.now(),
                type: 1,
                word: key,
                appid: 16073360
            };
            params['sign'] = paramsSign(params);
            return axios.get('https://api-qianqian.taihe.com/v1/search', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData;
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    const resp = {code: 500, msg: data["errmsg"], data: null};
                    return JSON.stringify(resp)
                }
                const result = respData["data"];
                const newArray = result["typeTrack"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['assetId'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["isVip"],
                        artist: element["artist"].map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                        album: {
                            package: "xyz.yhsj.baidu",
                            id: element["albumAssetCode"],
                            title: element["albumTitle"],
                            pic: `${element["pic"]}@w_400,h_400`,
                        },
                        lyric: element["lyric"],
                    }
                });
                return {
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
                }
            })
        }
    },
    url: {
        playUrl: function (song) {
            const mySong = JSON.parse(song);
            const params = {TSID: mySong["id"], timestamp: Date.now(), appid: 16073360, rate: mySong['rate'] ?? 64};
            params['sign'] = paramsSign(params);
            return axios.get('https://api-qianqian.taihe.com/v1/song/tracklink', {
                headers: headers,
                params: params
            }).then(async function (data) {
                let respData;
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: respData["errmsg"], data: null}
                }
                try {
                    const path = respData["data"]["lyric"];
                    if (path != null && path !== "") {
                        const response = await axios.get(path);
                        mySong["lyric"] = response.data
                    }
                } catch (error) {
                    console.error('Error:', error)
                }
                mySong["url"] = respData["data"]["path"];
                return {code: 200, msg: '操作成功', data: mySong}
            })
        }
    },
    playList: {
        type: function () {
            const params = {timestamp: Date.now(), appid: 16073360,}
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/tracklist/category', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newArray = result.map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['id'],
                        name: element['categoryName'],
                        subType: element['subCate'].map(function (element) {
                            return {package: 'xyz.yhsj.baidu', id: element['id'], name: element['categoryName'],}
                        })
                    }
                })
                return {code: 200, msg: '操作成功', data: newArray}
            })
        },
        list: function playList(type, page = 0, size = 20) {
            const params = {pageNo: parseInt(page) + 1, pageSize: size, timestamp: Date.now(), appid: 16073360,}
            console.log(type)
            if (type !== "null") {
                params["subCateId"] = type
            }
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/tracklist/list', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['id'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element['desc'],
                        desc: element['desc'],
                        songCount: element['trackCount'],
                    }
                })
                return {
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
                }
            })
        },
        info: function playListInfo(playlist, page = 0, size = 20) {
            console.log(playlist)
            console.log(typeof playlist)
            const myPlaylist = JSON.parse(playlist)
            const params = {
                id: myPlaylist["id"],
                pageNo: parseInt(page) + 1,
                pageSize: size,
                timestamp: Date.now(),
                appid: 16073360
            }
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/tracklist/info', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newPlaylist = {
                    package: 'xyz.yhsj.baidu',
                    id: result['id'],
                    pic: `${result["pic"]}@w_400,h_400`,
                    title: result['title'],
                    subTitle: result['desc'],
                    desc: result['desc'],
                    songCount: result['trackCount'],
                }
                const newArray = result["trackList"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['assetId'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["isVip"],
                        artist: element["artist"].map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                        album: {
                            package: "xyz.yhsj.baidu",
                            id: element["albumAssetCode"],
                            title: element["albumTitle"],
                            pic: `${element["pic"]}@w_400,h_400`,
                        },
                        lyric: element["lyric"],
                    }
                })
                newPlaylist['songs'] = newArray
                return {
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
                }
            })
        }
    },
    album: {
        type: function albumType() {
            return {code: 200, msg: '操作成功', data: []}
        },
        list: function albumList(type, page = 0, size = 20) {
            const params = {pageNo: parseInt(page) + 1, pageSize: size, timestamp: Date.now(), appid: 16073360,}
            console.log(type)
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/album/list', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['albumAssetCode'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        artist: element["artist"].map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                        songCount: element['trackCount'],
                    }
                })
                return {
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
                }
            })
        },
        info: function albumInfo(album, page = 0, size = 20) {
            console.log(album)
            console.log(typeof album)
            const myAlbum = JSON.parse(album)
            const params = {albumAssetCode: myAlbum["id"], timestamp: Date.now(), appid: 16073360}
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/album/info', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newAlbum = {
                    package: 'xyz.yhsj.baidu',
                    id: result['albumAssetCode'],
                    pic: `${result["pic"]}@w_400,h_400`,
                    title: result['title'],
                    subTitle: result["artist"]?.map(function (ar) {
                        return ar["name"]
                    }).join(","),
                    artist: result["artist"]?.map(function (ar) {
                        return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                    }),
                    desc: result["introduce"],
                }
                const newArray = result["trackList"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['assetId'],
                        pic: `${result["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: result["artist"]?.map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["isVip"],
                        artist: result["artist"]?.map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                    }
                })
                newAlbum['songs'] = newArray
                newAlbum['songCount'] = newArray.length
                return {
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
                }
            })
        },
    },
    rec: {
        playlist: function playListRec() {
            const params = {timestamp: Date.now(), appid: 16073360,}
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/index', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"].find(function (data) {
                    return data["type"] === "tracklist"
                })
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['id'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element['desc'],
                        desc: element['desc'],
                        songCount: element['trackCount'],
                    }
                })
                return {code: 200, msg: '操作成功', data: newArray}
            })
        },
        album: function albumRec() {
            const params = {timestamp: Date.now(), appid: 16073360,}
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/index', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"].find(function (data) {
                    return data["type"] === "album"
                })
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['albumAssetCode'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"]?.map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        artist: element["artist"]?.map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                        songCount: element['trackCount'],
                    }
                })
                return {code: 200, msg: '操作成功', data: newArray,}
            })
        },
        song: function songRec() {
            const params = {timestamp: Date.now(), appid: 16073360,}
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/index', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"].find(function (data) {
                    return data["type"] === "song"
                })
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['assetId'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["isVip"],
                        artist: element["artist"].map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                        album: {
                            package: "xyz.yhsj.baidu",
                            id: element["albumAssetCode"],
                            title: element["albumTitle"],
                            pic: `${element["pic"]}@w_400,h_400`,
                        },
                        lyric: element["lyric"],
                    }
                })
                return {code: 200, msg: '操作成功', data: newArray}
            })
        }
    },
    rank: {
        list: function rankList() {
            const params = {timestamp: Date.now(), appid: 16073360,}
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/bd/category', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const newArray = respData["data"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['bdid'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                    }
                })
                const type = [{package: 'xyz.yhsj.baidu', title: '官方榜', rankList: newArray,}]
                return {code: 200, msg: '操作成功', data: type}
            })
        },
        info: function rankInfo(rank, page = 0, size = 20) {
            const myRank = JSON.parse(rank)
            const params = {
                bdid: myRank["id"],
                pageNo: parseInt(page) + 1,
                pageSize: size,
                timestamp: Date.now(),
                appid: 16073360
            }
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/bd/list', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newAlbum = {
                    package: 'xyz.yhsj.baidu',
                    id: result['bdid'],
                    pic: `${myRank["pic"]}`,
                    title: result['title'],
                    songCount: result['total']
                }
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['assetId'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["isVip"],
                        artist: element["artist"].map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                    }
                })
                newAlbum['songs'] = newArray
                return {
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
                }
            })
        }
    },
    artist: {
        type: function artistType() {
            const newArray = [{
                package: 'xyz.yhsj.baidu',
                id: "artistFristLetter",
                name: '首字母',
                subType: [{package: 'xyz.yhsj.baidu', id: "", name: '全部'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'A',
                    name: 'A'
                }, {
                    package: 'xyz.yhsj.baidu',
                    id: 'B',
                    name: 'B'
                }, {package: 'xyz.yhsj.baidu', id: 'C', name: 'C'}, {package: 'xyz.yhsj.baidu', id: 'D', name: 'D'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'E',
                    name: 'E'
                }, {package: 'xyz.yhsj.baidu', id: 'F', name: 'F'}, {package: 'xyz.yhsj.baidu', id: 'G', name: 'G'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'H',
                    name: 'H'
                }, {package: 'xyz.yhsj.baidu', id: 'I', name: 'I'}, {package: 'xyz.yhsj.baidu', id: 'J', name: 'J'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'K',
                    name: 'K'
                }, {package: 'xyz.yhsj.baidu', id: 'L', name: 'L'}, {package: 'xyz.yhsj.baidu', id: 'M', name: 'M'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'N',
                    name: 'N'
                }, {package: 'xyz.yhsj.baidu', id: 'O', name: 'O'}, {package: 'xyz.yhsj.baidu', id: 'P', name: 'P'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'Q',
                    name: 'Q'
                }, {package: 'xyz.yhsj.baidu', id: 'R', name: 'R'}, {package: 'xyz.yhsj.baidu', id: 'S', name: 'S'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'T',
                    name: 'T'
                }, {package: 'xyz.yhsj.baidu', id: 'U', name: 'U'}, {package: 'xyz.yhsj.baidu', id: 'V', name: 'V'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'W',
                    name: 'W'
                }, {package: 'xyz.yhsj.baidu', id: 'X', name: 'X'}, {package: 'xyz.yhsj.baidu', id: 'Y', name: 'Y'}, {
                    package: 'xyz.yhsj.baidu',
                    id: 'Z',
                    name: 'Z'
                }, {package: 'xyz.yhsj.baidu', id: 'other', name: '#'},]
            }, {
                package: 'xyz.yhsj.baidu',
                id: "artistGender",
                name: '性别',
                subType: [{package: 'xyz.yhsj.baidu', id: "", name: '全部'}, {
                    package: 'xyz.yhsj.baidu',
                    id: '男',
                    name: '男'
                }, {
                    package: 'xyz.yhsj.baidu',
                    id: '女',
                    name: '女'
                }, {package: 'xyz.yhsj.baidu', id: '组合', name: '组合'}, {
                    package: 'xyz.yhsj.baidu',
                    id: '乐队',
                    name: '乐队'
                }]
            }, {
                package: 'xyz.yhsj.baidu',
                id: "artistRegion",
                name: '地区',
                subType: [{package: 'xyz.yhsj.baidu', id: "", name: '全部'}, {
                    package: 'xyz.yhsj.baidu',
                    id: '内地',
                    name: '内地'
                }, {
                    package: 'xyz.yhsj.baidu',
                    id: '港台',
                    name: '港台'
                }, {package: 'xyz.yhsj.baidu', id: '欧美', name: '欧美'}, {
                    package: 'xyz.yhsj.baidu',
                    id: '韩国',
                    name: '韩国'
                }, {
                    package: 'xyz.yhsj.baidu',
                    id: '日本',
                    name: '日本'
                }, {package: 'xyz.yhsj.baidu', id: '其他', name: '其他'}]
            }]
            return {code: 200, msg: '操作成功', data: newArray}
        },
        list: function artistList(type, page = 0, size = 20) {
            const params = JSON.parse(type ?? "{}")
            params["pageNo"] = parseInt(page) + 1
            params["pageSize"] = size
            params["timestamp"] = Date.now()
            params["appid"] = 16073360
            console.log(type)
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/artist/list', {params}, {headers: headers}).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['artistCode'],
                        pic: element["pic"],
                        name: element['name'],
                    }
                })
                return {
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
                }
            })
        },
        info: function artistInfo(artist, page = 0, size = 20) {
            const myPlaylist = JSON.parse(artist)
            const params = {
                id: myPlaylist["id"],
                pageNo: parseInt(page) + 1,
                pageSize: size,
                timestamp: Date.now(),
                appid: 16073360
            }
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/tracklist/info', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newPlaylist = {
                    package: 'xyz.yhsj.baidu',
                    id: result['id'],
                    title: result['title'],
                    subTitle: result['desc'],
                    desc: result['desc'],
                    songCount: result['trackCount'],
                }
                const newArray = result["trackList"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['assetId'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["isVip"],
                        artist: element["artist"].map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                        album: {
                            package: "xyz.yhsj.baidu",
                            id: element["albumAssetCode"],
                            title: element["albumTitle"],
                            pic: `${element["pic"]}@w_400,h_400`,
                        },
                        lyric: element["lyric"],
                    }
                })
                newPlaylist['songs'] = newArray
                return {
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
                }
            })
        },
        song: function artistSong(artist, page = 0, size = 20) {
            const myArtist = JSON.parse(artist)
            const params = {
                artistCode: myArtist["id"],
                pageNo: parseInt(page) + 1,
                pageSize: size,
                timestamp: Date.now(),
                appid: 16073360
            }
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/artist/song', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['assetId'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["isVip"],
                        artist: element["artist"].map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                    }
                })
                return {
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
                }
            })
        },
        album: function artistAlbum(artist, page = 0, size = 20) {
            const myArtist = JSON.parse(artist)
            const params = {
                artistCode: myArtist["id"],
                pageNo: parseInt(page) + 1,
                pageSize: size,
                timestamp: Date.now(),
                appid: 16073360
            }
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/artist/album', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newArray = result["result"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.baidu',
                        id: element['albumAssetCode'],
                        pic: `${element["pic"]}@w_400,h_400`,
                        title: element['title'],
                        subTitle: element["artist"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        artist: element["artist"].map(function (ar) {
                            return {package: "xyz.yhsj.baidu", id: ar["artistCode"], name: ar["name"], pic: `${ar["pic"]}`}
                        }),
                        desc: element['introduce'],
                    }
                })
                return {
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
                }
            })
        },
    },
    parse: {
        playlist: function parsePlayList(url) {
            console.log(url)
            if (!url.toString().includes("music.91q.com") && !url.toString().includes("music.taihe.com")) {
                return JSON.stringify({code: 500, msg: "暂不支持此链接"})
            }
            console.log(url)
            var id
            let pattern = /[/][\d]+[?]*/g
            let matches = url.toString().match(pattern)
            if (matches !== null) {
                id = matches[0].slice(1, -1)
            }
            console.log(url)
            console.log(id)
            const params = {id: id, pageNo: 1, pageSize: 10, timestamp: Date.now(), appid: 16073360}
            params['sign'] = paramsSign(params)
            return axios.get('https://api-qianqian.taihe.com/v1/tracklist/info', {
                headers: headers,
                params: params
            }).then(function (data) {
                let respData
                if (typeof data.data === 'string') {
                    respData = JSON.parse(data.data)
                } else {
                    respData = data.data
                }
                if (respData["errno"] !== 22000) {
                    return {code: 500, msg: data["errmsg"], data: null}
                }
                const result = respData["data"]
                const newPlaylist = {
                    package: 'xyz.yhsj.baidu',
                    id: result['id'],
                    pic: `${result["pic"]}@w_400,h_400`,
                    title: result['title'],
                    subTitle: result['desc'],
                    desc: result['desc'],
                    songCount: result['trackCount'],
                }
                return {code: 200, msg: '操作成功', data: newPlaylist,}
            })
        }
    }
}

function paramsSign(params) {
    const paramsString = Object.entries(params).map(([key, value]) => `${key}=${value}`).sort().join('&')
    const signStr = `${paramsString.toString()}0b50b02fd0d73a9c4c8c3a781c30845f`
    return CryptoJS.MD5(signStr).toString()
}

true