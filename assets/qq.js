// ==MixMusicPlugin==
// @name         QQ音乐
// @site         qq
// @package      xyz.yhsj.qq
// @version      0.0.1
// @versionCode  1
// @author       永恒瞬间
// @icon         https://y.qq.com/favicon.ico
// @webSite      https://y.qq.com
// @updateUrl    https://y.qq.com
// @desc         官方插件
// ==/MixMusicPlugin==


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

const music = {
    // type 0:单曲, 1:相关歌手,2:专辑,3:歌单,4:MV,7:歌词,8:用户
    search: {
        music: async function (key, page = 0, size = 20) {
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

                const respData = data.data

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }


                const newArray = respData["req"]["data"]["body"]["song"]["list"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: {
                            id: element["id"],
                            mid: element["mid"],
                            mediaId: element["file"]["media_mid"]
                        },
                        quality: getQualities(element["file"], element["mid"]),
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                        title: element['title'],
                        subTitle: element["singer"].map(function (ar) {
                            return ar["title"]
                        }).join(","),
                        vip: element["pay"]["pay_play"],
                        artist: element["singer"].map(function (ar) {
                            return {
                                package: "xyz.yhsj.qq",
                                id: ar["mid"],
                                title: ar["title"],
                                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                            }
                        }),
                        album: {
                            package: "xyz.yhsj.qq",
                            id: element["album"]["mid"],
                            title: element["album"]["title"],
                            pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                        },
                    };
                });
                return {
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
            });
        },
        album: async function (key, page = 0, size = 20) {
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
                            search_type: 2,
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

                const respData = data.data

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const newArray = respData["req"]["data"]["body"]["album"]["list"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: element['albumMID'],
                        pic: element['albumPic'],
                        title: element['albumName'],
                        subTitle: element["singer_list"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        artist: element["singer_list"].map(function (ar) {
                            return {
                                package: "xyz.yhsj.qq",
                                id: ar["mid"],
                                title: ar["name"],
                            }
                        }),
                    };
                });
                return {
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
            });
        },
        artist: async function (key, page = 0, size = 20) {
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
                            search_type: 1,
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

                const respData = data.data

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const newArray = respData["req"]["data"]["body"]["singer"]["list"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: element['singerMID'],
                        pic: element["singerPic"],
                        title: element['singerName'],
                    };
                });
                return {
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
            });
        },
        playlist: async function (key, page = 0, size = 20) {
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
                            search_type: 3,
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

                const respData = data.data

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const newArray = respData["req"]["data"]["body"]["songlist"]["list"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: parseInt(element['dissid']),
                        pic: element["imgurl"],
                        title: element["dissname"],
                        subTitle: element["introduction"],
                        desc: element["introduction"],
                        songCount: element["song_count"],
                    };
                });
                return {
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
            });
        }
    },
    url: {
        playUrl: async function playUrl(song) {
            try {
                const lrcParams = {
                    nobase64: 1,
                    format: 'json',
                    songmid: song["id"]["mid"],
                }
                console.log(JSON.stringify(lrcParams))
                const response = await axios.get("https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg", {
                    headers: {Referer: 'https://y.qq.com/'},
                    params: lrcParams
                });
                song["lyric"] = response.data["lyric"];

            } catch (error) {
                console.error('Error:', error);
            }

            // const typeObj = typeMap[128];
            // const file = `${typeObj.s}${song["id"]["id"]}${song["id"]["mid"]}${typeObj.e}`;

            // console.log(file)
            console.log(song)

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
                            // filename: typeMap.map(function (element) {
                            //     return `${element.s}${song["id"]["mediaId"]}${element.e}`;
                            // }),
                            songmid: [`${song["id"]["mid"]}`],
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

                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                console.log(JSON.stringify(respData))

                try {
                    const urls = respData["req"]["data"]["midurlinfo"].filter(item => item["purl"] !== "");
                    const sip = respData["req"]["data"]["sip"]
                    urls.forEach(function (ss) {

                        const url = `${sip[0]}${ss["purl"]}`

                        console.log(url)

                    })


                    if (urls.length !== 0 && sip.length !== 0) {
                        const url = `${sip[0]}${urls[0]["purl"]}`

                        console.log(url)

                        song["url"] = url;
                    }

                } catch (error) {
                    console.error('Error:', error);
                }
                return {
                    code: 200,
                    msg: '操作成功',
                    data: song
                };
            });
        },
        download: async function download(download) {
            // {
            //     package: "xyz.yhsj.qq",
            //         id: {
            //         mid: mid,
            //         mediaId: qualities["media_mid"],
            //         prefix: "RS01",
            //         suffix: "flac"
            // },
            //     title: "hires",
            //         quality: 1000,
            //     size: qualities["size_hires"],
            // }

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
                            // filename: typeMap.map(function (element) {
                            //     return `${element.s}${song["id"]["mediaId"]}${element.e}`;
                            // }),
                            filename: [
                                `${download.quality["id"]["prefix"]}${download.quality["id"]["mediaId"]}.${download.quality["id"]["suffix"]}`
                            ],
                            songmid: [`${download.quality["id"]["mid"]}`],
                            songtype: [0],
                            uin: "0",
                            loginflag: 1,
                            platform: "20",
                        }
                    }
                })
            }
            console.log(params)

            let cookie = await getCookie();
            console.log(cookie)
            headers.Cookie = cookie;

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(async function (data) {

                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                console.log(JSON.stringify(respData))


                try {
                    const urls = respData["req"]["data"]["midurlinfo"].filter(item => item["purl"] !== "");
                    const sip = respData["req"]["data"]["sip"]
                    urls.forEach(function (ss) {
                        const url = `${sip[0]}${ss["purl"]}`
                        console.log(url)
                    })

                    if (urls.length !== 0 && sip.length !== 0) {
                        const url = `${sip[0]}${urls[0]["purl"]}`
                        console.log(url)
                        download["url"] = url;
                    }

                } catch (error) {
                    console.error('Error:', error);
                }
                return {
                    code: 200,
                    msg: '操作成功',
                    data: download
                };
            });
        }
    },
    playList: {
        type: function playListType() {
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

                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["allTag"]["data"]["v_group"]

                const newArray = result.map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: element['group_id'],
                        title: element['group_name'],
                        subType: element['v_item'].map(function (element) {
                            return {
                                package: 'xyz.yhsj.qq',
                                id: element['id'],
                                title: element['name'],
                            };
                        })
                    };
                });
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray
                };
            });
        },
        list: function playList(type, page = 0, size = 20) {

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
                            category_id: type === "null" ? 3317 : parseInt(type["id"]),
                        },
                    }
                })
            }

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {


                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["playlist"]["data"]["content"]

                const newArray = result["v_item"].map(function (element) {

                    return {
                        package: 'xyz.yhsj.qq',
                        id: element["basic"]['tid'],
                        pic: element["basic"]["cover"]["default_url"],
                        title: element["basic"]["title"],
                        subTitle: element["basic"]["desc"],
                        desc: element["basic"]["desc"],
                        songCount: element["basic"]["song_cnt"],
                    };
                });
                return {
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
            });
        },
        info: function playListInfo(playlist, page = 0, size = 20) {

            console.log(playlist["id"])
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
                            disstid: playlist["id"],
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

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {
                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                console.log(JSON.stringify(respData))

                const result = respData["playlist"]["data"]

                const newPlaylist = {
                    package: 'xyz.yhsj.qq',
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
                        package: 'xyz.yhsj.qq',
                        id: {
                            id: element["id"],
                            mid: element["mid"],
                            mediaId: element["file"]["media_mid"]
                        },
                        quality: getQualities(element["file"], element["mid"]),
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                        title: element['title'],
                        subTitle: element["singer"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["pay"]["pay_play"],
                        artist: element["singer"].map(function (ar) {
                            return {
                                package: "xyz.yhsj.qq",
                                id: ar["mid"],
                                title: ar["name"],
                                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                            }
                        }),
                        album: {
                            package: "xyz.yhsj.qq",
                            id: element["album"]["mid"],
                            title: element["album"]["title"],
                            pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                        },
                    };
                });

                newPlaylist['songs'] = newArray

                return {
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
            });
        }
    },
    album: {
        type: function albumType() {
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

                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["allTag"]["data"]["area"]

                const newArray = [{
                    package: 'xyz.yhsj.qq',
                    id: null,
                    title: "区域",
                    subType: result.map(function (element) {
                        return {
                            package: 'xyz.yhsj.qq',
                            id: element['id'],
                            title: element['name'],
                        };
                    })
                }]
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray
                };
            });
        },
        list: function albumList(type, page = 0, size = 20) {
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
                            area: type === "null" ? 1 : parseInt(type["id"]),
                        },
                    }
                })
            }

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {
                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["album"]["data"]

                const newArray = result["albums"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: element['mid'],
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["mid"]}.jpg`,
                        title: element['name'],
                        subTitle: element["singers"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        artist: element["singers"].map(function (ar) {
                            return {
                                package: "xyz.yhsj.qq",
                                id: ar["artistCode"],
                                title: ar["name"],
                                pic: `${ar["pic"]}`
                            }
                        }),
                    };
                });
                return {
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
            });
        },
        info: function albumInfo(album, page = 0, size = 20) {
            // 定义查询参数
            const params = {
                data: JSON.stringify({
                    comm: {ct: 20, cv: 1807, uin: "0"},
                    //该歌手其他专辑
                    otherAlbum: {
                        module: "music.musichallAlbum.OtherAlbumList",
                        method: "OtherAlbumList",
                        param: {"albumMid": album["id"], "order": 0, "num": 6}
                    },
                    //专辑信息
                    albumInfo: {
                        module: "music.musichallAlbum.AlbumInfoServer",
                        method: "GetAlbumDetail",
                        param: {albumMid: album["id"]}
                    },
                    //专辑歌曲
                    albumSong: {
                        module: "music.musichallAlbum.AlbumSongList",
                        method: "GetAlbumSongList",
                        param: {
                            albumMid: album["id"],
                            begin: parseInt(page) * parseInt(size),
                            num: parseInt(size),
                            order: 2
                        }
                    },
                    //是否收藏？
                    collect: {
                        module: "music.musicasset.AlbumFavRead",
                        method: "IsAlbumFan",
                        param: {
                            v_albumMid: [album["albumMid"]]
                        }
                    },
                })
            }

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {

                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }


                const info = respData["albumInfo"]["data"]
                const result = respData["albumSong"]["data"]

                const newAlbum = {
                    package: 'xyz.yhsj.qq',
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
                            package: "xyz.yhsj.qq",
                            id: ar["mid"],
                            title: ar["name"],
                            pic: `https://y.qq.com/music/photo_new/T001R300x300M000${ar["mid"]}.jpg`
                        }
                    }),

                }
                const newArray = result["songList"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: {
                            id: element["songInfo"]["id"],
                            mid: element["songInfo"]["mid"],
                            mediaId: element["songInfo"]["file"]["media_mid"]
                        },
                        quality: getQualities(element["songInfo"]["file"], element["songInfo"]["mid"]),
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["songInfo"]["album"]["mid"]}.jpg`,
                        title: element["songInfo"]['title'],
                        subTitle: element["songInfo"]["singer"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["songInfo"]["pay"]["pay_play"],
                        artist: element["songInfo"]["singer"].map(function (ar) {
                            return {
                                package: "xyz.yhsj.qq",
                                id: ar["mid"],
                                title: ar["name"],
                                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                            }
                        }),
                        album: {
                            package: "xyz.yhsj.qq",
                            id: element["songInfo"]["album"]["mid"],
                            title: element["songInfo"]["album"]["title"],
                            pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["songInfo"]["album"]["mid"]}.jpg`,
                        },
                    };
                });

                newAlbum['songs'] = newArray

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
                };
            });
        },
    },
    rec: {
        playlist: function playListRec() {
            // 定义查询参数
            const params = {
                data: JSON.stringify({
                    comm: {ct: 20, cv: 1807, uin: "0"},
                    playlist: {
                        module: "music.playlist.PlaylistSquare",
                        method: "GetRecommendFeed",
                        param: {"From": 0, "Size": 10},
                    }
                })
            }

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {

                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["playlist"]["data"]["List"]

                const newArray = result.map(function (element) {

                    return {
                        package: 'xyz.yhsj.qq',
                        id: element["Playlist"]["basic"]['tid'],
                        pic: element["Playlist"]["basic"]["cover"]["default_url"],
                        title: element["Playlist"]["basic"]["title"],
                        subTitle: element["Playlist"]["basic"]["desc"],
                        desc: element["Playlist"]["basic"]["desc"],
                        songCount: element["Playlist"]["basic"]["song_cnt"],
                    };
                });
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray
                };
            });
        },
        album: function albumRec() {
            // 定义查询参数
            const params = {
                data: JSON.stringify({
                    comm: {ct: 20, cv: 1807, uin: "0"},
                    album: {
                        module: "newalbum.NewAlbumServer",
                        method: "get_new_album_info",
                        param: {
                            last_id: "",
                            start: 0,
                            num: 10,
                            area: 1,
                        },
                    }
                })
            }

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {
                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["album"]["data"]

                const newArray = result["albums"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: element['mid'],
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["mid"]}.jpg`,
                        title: element['name'],
                        subTitle: element["singers"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        artist: element["singers"].map(function (ar) {
                            return {
                                package: "xyz.yhsj.qq",
                                id: ar["artistCode"],
                                title: ar["name"],
                                pic: `${ar["pic"]}`
                            }
                        }),
                    };
                });
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray
                };
            });
        },
        song: function songRec() {
            // 定义查询参数
            const params = {
                data: JSON.stringify({
                    comm: {ct: 20, cv: 1087},
                    newSong: {
                        module: "newsong.NewSongServer",
                        method: "get_new_song_info",
                        param: {
                            type: 5
                        }
                    }
                })
            }

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params,
            }).then(function (data) {

                const respData = data.data

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const newArray = respData["newSong"]["data"]["songlist"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: {
                            id: element["id"],
                            mid: element["mid"],
                            mediaId: element["file"]["media_mid"]
                        },
                        quality: getQualities(element["file"], element["mid"]),
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                        title: element['title'],
                        subTitle: element["singer"].map(function (ar) {
                            return ar["title"]
                        }).join(","),
                        vip: element["pay"]["pay_play"],
                        artist: element["singer"].map(function (ar) {
                            return {
                                package: "xyz.yhsj.qq",
                                id: ar["mid"],
                                title: ar["title"],
                                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                            }
                        }),
                        album: {
                            package: "xyz.yhsj.qq",
                            id: element["album"]["mid"],
                            title: element["album"]["title"],
                            pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                        },
                    };
                });
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray.slice(0, 10)
                };
            });
        }
    },
    rank: {
        list: function rankList() {
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
                    rankList: {
                        module: "musicToplist.ToplistInfoServer",
                        method: "GetAll",
                        param: {}
                    }
                })
            }

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {
                const respData = data.data

                if (respData["code"] !== 0) {
                    return {code: 500, msg: '请求失败', data: null};
                }

                const result = respData["rankList"]["data"]["group"]

                const newArray = result.map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: element['groupId'],
                        title: element['groupName'],
                        rankList: element['toplist'].map(function (element) {
                            return {
                                package: 'xyz.yhsj.qq',
                                id: {
                                    id: element['topId'],
                                    period: element['period']
                                },
                                title: element['title'],
                                pic: element['frontPicUrl'],
                            };
                        })
                    };
                });


                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray
                };
            });
        },
        info: function rankInfo(rank, page = 0, size = 20) {

            // 定义查询参数
            const params = {
                data: JSON.stringify({
                    comm: {ct: 20, cv: 1807, uin: "0"},
                    rank: {
                        module: "musicToplist.ToplistInfoServer",
                        method: "GetDetail",
                        param: {
                            topid: rank["id"]["id"],
                            period: rank["id"]["period"],
                            offset: parseInt(page) * parseInt(size),
                            num: parseInt(size),
                        }
                    }
                })
            }

            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {

                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const info = respData["rank"]["data"]["data"]
                const result = respData["rank"]["data"]["songInfoList"]

                const newAlbum = {
                    package: 'xyz.yhsj.qq',
                    id: {
                        id: info["topId"],
                        period: info["period"],
                    },
                    pic: info["headPicUrl"],
                    title: info['title'],
                    desc: info['intro'],
                    songCount: info['totalNum']
                }
                const newArray = result.map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: {
                            id: element["id"],
                            mid: element["mid"],
                            mediaId: element["file"]["media_mid"]
                        },
                        quality: getQualities(element["file"], element["mid"]),
                        pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["mid"]}.jpg`,
                        title: element['title'],
                        subTitle: element["singer"].map(function (ar) {
                            return ar["name"]
                        }).join(","),
                        vip: element["pay"]["pay_play"],
                        artist: element["singer"].map(function (ar) {
                            return {
                                package: "xyz.yhsj.qq",
                                id: ar["mid"],
                                title: ar["name"],
                                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                            }
                        }),
                        album: {
                            package: "xyz.yhsj.qq",
                            id: element["album"]["mid"],
                            title: element["album"]["title"],
                            pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["album"]["pmid"]}.jpg`,
                        },
                    };
                });

                newAlbum['songs'] = newArray

                return {
                    code: 200,
                    msg: '操作成功',
                    data: newAlbum,
                    page: {
                        first: parseInt(page) === 0,
                        last: parseInt(size) * (parseInt(page) + 1) >= parseInt(info['totalNum']),
                        page: parseInt(page) + 1,
                        size: parseInt(size),
                        number: newArray.length,
                        totalPages: Math.floor(info['totalNum'] / parseInt(size)),
                        totalSize: info['totalNum']
                    }
                };
            });
        }
    },
    artist: {
        type: function artistType() {

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
                    singerList: {
                        module: "music.musichallSinger.SingerList",
                        method: "GetSingerListIndex",
                        param: {
                            area: -100,
                            sex: -100,
                            genre: -100,
                            index: -100,
                            sin: 0,
                            cur_page: 1
                        }
                    }
                })
            }
            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {
                console.log(JSON.stringify(data))
                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["singerList"]["data"]["tags"]

                const group = [
                    {id: "area", title: "区域"},
                    {id: "genre", title: "类型"},
                    {id: "index", title: "首字母"},
                    {id: "sex", title: "性别"},
                ];
                const newArray = group.map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: element['id'],
                        title: element['title'],
                        subType: result[element['id']].map(function (element) {
                            return {
                                package: 'xyz.yhsj.qq',
                                id: element['id'],
                                title: element['name'],
                            };
                        })
                    };
                });
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray
                };
            });
        },
        list: function artistList(type, page = 0, size = 20) {

            const sin = parseInt(page) * 80;

            const myType = JSON.parse(type ?? "{}");

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
                    singerList: {
                        module: "music.musichallSinger.SingerList",
                        method: "GetSingerListIndex",
                        param: {
                            area: myType["area"] ?? -100,
                            sex: myType["sex"] ?? -100,
                            genre: myType["genre"] ?? -100,
                            index: myType["index"] ?? -100,
                            sin: sin,
                            cur_page: parseInt(page) + 1
                        }
                    }
                })
            }
            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {
                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["singerList"]["data"]

                const newArray = result["singerlist"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: element['singer_mid'],
                        pic: element["singer_pic"],
                        title: element['singer_name'],
                    };
                });
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray,
                    page: {
                        first: parseInt(page) === 0,
                        last: 80 * (parseInt(page) + 1) >= parseInt(result['total']),
                        page: parseInt(page) + 1,
                        size: 80,
                        number: newArray.length,
                        totalPages: Math.floor(result['total'] / 80),
                        totalSize: result['total']
                    }
                };
            });
        },
        info: function artistInfo(artist, page = 0, size = 20) {

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
                        detail: {
                            method: "GetSingerDetail",
                            module: "music.musichallSinger.SingerInfoInter",
                            param: {
                                singer_mids: [artist["id"]],
                                ex_singer: 1,
                                wiki_singer: 1,
                                group_singer: 0,
                                pic: 1,
                                photos: 0
                            }
                        }
                    }
                )
            }
            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {
                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }

                const result = respData["detail"]["data"]["singer_list"].first

                const newPlaylist = {
                    package: 'xyz.yhsj.qq',
                    id: result["basic_info"]['singer_mid'],
                    title: result["basic_info"]['name'],
                    subTitle: result["ex_info"]['desc'],
                    desc: result["ex_info"]['desc'],
                    songCount: result['trackCount'],
                }

                return {
                    code: 200,
                    msg: '操作成功',
                    data: newPlaylist,
                };
            });
        },
        detail: {
            song: function artistSong(artist, page = 0, size = 20) {
                // 定义查询参数
                const params = {
                    data: JSON.stringify({
                            comm: {ct: 24, cv: 0},
                            //歌曲
                            singerSongList: {
                                module: "musichall.song_list_server",
                                method: "GetSingerSongList",
                                param: {
                                    singerMid: artist["id"],
                                    begin: parseInt(page) * parseInt(size),
                                    num: parseInt(size),
                                    order: 1
                                }
                            },
                        }
                    )
                }

                return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                    headers: headers,
                    params: params
                }).then(function (data) {
                    const respData = data.data

                    if (respData["code"] !== 0) {
                        return {
                            code: 500,
                            msg: '请求失败',
                            data: null
                        };
                    }


                    const result = respData["singerSongList"]["data"]

                    const newArray = result["songList"].map(function (element) {
                        return {
                            package: 'xyz.yhsj.qq',
                            id: {
                                id: element["songInfo"]["id"],
                                mid: element["songInfo"]["mid"],
                                mediaId: element["songInfo"]["file"]["media_mid"]
                            },
                            quality: getQualities(element["songInfo"]["file"], element["songInfo"]["mid"]),
                            pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["songInfo"]["album"]["mid"]}.jpg`,
                            title: element["songInfo"]['title'],
                            subTitle: element["songInfo"]["singer"].map(function (ar) {
                                return ar["name"]
                            }).join(","),
                            vip: element["songInfo"]["pay"]["pay_play"],
                            artist: element["songInfo"]["singer"].map(function (ar) {
                                return {
                                    package: "xyz.yhsj.qq",
                                    id: ar["mid"],
                                    title: ar["name"],
                                    pic: `https://y.qq.com/music/photo_new/T002R300x300M000${ar["mid"]}.jpg`
                                }
                            }),
                            album: {
                                package: "xyz.yhsj.qq",
                                id: element["songInfo"]["album"]["mid"],
                                title: element["songInfo"]["album"]["title"],
                                pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["songInfo"]["album"]["mid"]}.jpg`,
                            },
                        };
                    });


                    return {
                        code: 200,
                        msg: '操作成功',
                        data: newArray,
                        page: {
                            first: parseInt(page) === 0,
                            last: (parseInt(page) + 1) * parseInt(size) > result["totalNum"],
                            page: parseInt(page) + 1,
                            size: parseInt(size),
                            number: newArray.length,
                            totalPages: Math.floor(result["totalNum"] / parseInt(size)),
                            totalSize: result["totalNum"]
                        }
                    };
                });
            },
            album: function artistAlbum(artist, page = 0, size = 20) {

                // 定义查询参数
                const params = {
                    data: JSON.stringify({
                            comm: {ct: 24, cv: 0},
                            //专辑
                            albumList: {
                                method: "GetAlbumList",
                                module: "music.musichallAlbum.AlbumListServer",
                                param: {
                                    singerMid: artist["id"],
                                    begin: parseInt(page) * parseInt(size),
                                    num: parseInt(size),
                                    order: 0,
                                    songNumTag: 0,
                                    singerID: 0
                                }
                            },
                        }
                    )
                }
                return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                    headers: headers,
                    params: params
                }).then(function (data) {
                    console.log(JSON.stringify(data))

                    const respData = data.data

                    if (respData["code"] !== 0) {
                        return {
                            code: 500,
                            msg: '请求失败',
                            data: null
                        };
                    }

                    const result = respData["albumList"]["data"]

                    const newArray = result["albumList"].map(function (element) {
                        return {
                            package: 'xyz.yhsj.qq',
                            id: element['albumMid'],
                            pic: `https://y.qq.com/music/photo_new/T002R300x300M000${element["albumMid"]}.jpg`,
                            title: element['albumName'],
                            subTitle: element["singerName"],
                            artist: [artist]
                        };
                    });


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
                    };
                });
            },
        }

    },
    parse: {
        playlist: function parsePlayList(url) {
            console.log(url)
            if (!url.toString().includes("y.qq.com")) {
                return JSON.stringify({code: 500, msg: "暂不支持此链接"});
            }
            var id
            if (url.toString().includes("y.qq.com/n/ryqq/playlist")) {
                let pattern = /[\d]{5,}/g;
                // 使用正则表达式的 exec() 方法来执行匹配
                let matches = url.toString().match(pattern);

                if (matches !== null) {
                    id = matches[0]
                }
            } else {
                let pattern = /id=[\d]{5,}/g;
                // 使用正则表达式的 exec() 方法来执行匹配
                let matches = url.toString().match(pattern);

                if (matches !== null) {
                    id = matches[0].slice(3)
                }
            }


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
                            disstid: parseInt(id),
                            userinfo: 1,
                            tag: 1,
                            orderlist: 1,
                            song_begin: 0,
                            song_num: 20,
                            onlysonglist: 0,
                            enc_host_uin: ""
                        }
                    }
                })
            }


            return axios.get('https://u.y.qq.com/cgi-bin/musicu.fcg', {
                headers: headers,
                params: params
            }).then(function (data) {
                const respData = data.data;

                if (respData["code"] !== 0) {
                    return {
                        code: 500,
                        msg: '请求失败',
                        data: null
                    };
                }


                const result = respData["playlist"]["data"]

                const newPlaylist = {
                    package: 'xyz.yhsj.qq',
                    id: result["dirinfo"]['id'],
                    pic: result["dirinfo"]["picurl"],
                    title: result["dirinfo"]['title'],
                    subTitle: result["dirinfo"]['desc'],
                    desc: result["dirinfo"]['desc'],
                    songCount: result["dirinfo"]['songnum'],
                }

                return {
                    code: 200,
                    msg: '操作成功',
                    data: newPlaylist
                };
            });
        }
    }
}

function getQualities(qualities, mid) {

    //             "media_mid": "002OWTIf4Tq1Xx",
    //             "size_24aac": 0,
    //             "size_48aac": 1188720,
    //             "size_96aac": 2389294,
    //             "size_192ogg": 4347940,
    //             "size_192aac": 4736900,
    //             "size_128mp3": 3136979,
    //             "size_320mp3": 7841993,
    //             "size_ape": 0,
    //             "size_flac": 41560304,
    //             "size_dts": 0,
    //             "size_hires": 0,
    //             "size_96ogg": 2242692,

    // const typeMap = [
    //     {q: "size_24aac", s: "C100", e: ".m4a"},
    //     {q: "size_48aac", s: "C200", e: ".m4a"},
    //     {q: "size_96aac", s: "C400", e: ".m4a"},
    //     {q: "size_128mp3", s: "M500", e: ".mp3"},
    //     {q: "size_192ogg", s: "O600", e: ".ogg"},
    //     {q: "size_192aac", s: "C600", e: ".m4a"},
    //     {q: "size_320mp3", s: "M800", e: ".mp3"},
    //     {q: "size_flac", s: "F000", e: ".flac"},
    //     {q: "size_ape", s: "A000", e: ".ape"},
    //     {q: "size_dts", s: "D00A", e: ".flac"},
    //     {q: "size_hires", s: "RS01", e: ".flac"},
    // ];
    const myQualities = [];

    if (qualities["size_24aac"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "C100",
                suffix: "m4a",
            },
            title: "24aac",
            quality: 24,
            size: qualities["size_24aac"],
        })
    }
    if (qualities["size_48aac"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "C200",
                suffix: "m4a",
            },
            title: "48aac",
            quality: 48,
            size: qualities["size_48aac"],
        })
    }
    if (qualities["size_96aac"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "C400",
                suffix: "m4a",
            },
            title: "96aac",
            quality: 96,
            size: qualities["size_96aac"],
        })
    }
    if (qualities["size_128mp3"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "M500",
                suffix: "mp3",
            },
            title: "128mp3",
            quality: 128,
            size: qualities["size_128mp3"],
        })
    }
    if (qualities["size_192ogg"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "O600",
                suffix: "ogg",
            },
            title: "192ogg",
            quality: 192,
            size: qualities["size_192ogg"],
        })
    }
    if (qualities["size_192aac"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "C600",
                suffix: "m4a",
            },
            title: "192aac",
            quality: 192,
            size: qualities["size_192aac"],
        })
    }
    if (qualities["size_320mp3"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "M800",
                suffix: "mp3",
            },
            title: "320mp3",
            quality: 320,
            size: qualities["size_320mp3"],
        })
    }
    if (qualities["size_flac"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "F000",
                suffix: "flac",
            },
            title: "flac",
            quality: 1000,
            size: qualities["size_flac"],
        })
    }
    if (qualities["size_ape"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "A000",
                suffix: "ape",
            },
            title: "ape",
            quality: 1000,
            size: qualities["size_ape"],
        })
    }
    if (qualities["size_dts"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "D00A",
                suffix: "flac",
            },
            title: "dts",
            quality: 1000,
            size: qualities["size_dts"],
        })
    }

    if (qualities["size_hires"] !== 0) {
        myQualities.push({
            package: "xyz.yhsj.qq",
            id: {
                mid: mid,
                mediaId: qualities["media_mid"],
                prefix: "RS01",
                suffix: "flac"
            },
            title: "hires",
            quality: 1000,
            size: qualities["size_hires"],
        })
    }

    return myQualities
}


true