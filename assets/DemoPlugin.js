// ==MixMusicPlugin==
// @name         DEMO插件
// @site         demo
// @package      xyz.yhsj.demo
// @version      0.0.1
// @versionCode  1
// @author       永恒瞬间
// @icon         https://new.myfreemp3juices.cc/favicon-32x32.png
// @webSite      https://new.myfreemp3juices.cc
// @updateUrl    https://new.myfreemp3juices.cc
// @desc         官方插件
// ==/MixMusicPlugin==

const music = {
    // type 0:单曲, 1:相关歌手,2:专辑,3:歌单,4:MV,7:歌词,8:用户
    search: {
        //这里实现可以用作音源匹配
        music: async function (key, page = 0, size = 20) {

            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    quality: [
                        {
                            package: "xyz.yhsj.demo",
                            id: "范类型id，可以字符串，可以集合",
                            title: "测试音质",
                            quality: 320,
                            size: 112200,
                        }
                    ],
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `标题${index}`,
                    subTitle: "副标题",
                    vip: index % 2 === 0 ? 0 : 1,
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],
                    album: {
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "专辑",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    },
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };

            //错误返回
            // return {
            //     code: 500,
            //     msg: '请求失败',
            //     data: null
            // };

        },
        album: async function (key, page = 0, size = 20) {

            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `专辑${index}`,
                    subTitle: "副标题",
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: "歌手id",
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };

        },
        artist: async function (key, page = 0, size = 20) {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `歌手${index}`
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        },
        playlist: async function (key, page = 0, size = 20) {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `歌单${index}`,
                    subTitle: "副标题",
                    desc: "描述",
                    songCount: 5,
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        },
    },
    url: {
        playUrl: async function playUrl(song) {
            song.lyric = "这是歌词";
            song.url = null;
            return {
                code: 200,
                msg: '操作成功',
                data: song
            };

        },
        download: async function download(download) {
            //来自音质quality中的内容
            // {
            //     package: "xyz.yhsj.demo",
            //     id: "范类型id，可以字符串，可以集合",
            //     title: "测试音质",
            //     quality: 320,
            //     size: 112200,
            // }
            download.url = null;
            return {
                code: 200,
                msg: '操作成功',
                data: download
            };
        }
    },
    playList: {
        type: function playListType() {

            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    title: "类型标题",
                    subType: [...Array(5)].map(function (_, index) {
                        return {
                            package: 'xyz.yhsj.demo',
                            id: "id",
                            title: "子类型标题",
                        };
                    })
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                //没有返回[]即可
                data: newArray
            };

        },
        list: function playList(type, page = 0, size = 20) {

            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `歌单${index}`,
                    subTitle: "副标题",
                    desc: "描述",
                    songCount: 5,
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        },
        info: function playListInfo(playlist, page = 0, size = 20) {

            const newPlaylist = {
                package: 'xyz.yhsj.demo',
                id: `范类型id，可以字符串，可以集合`,
                pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                title: `歌单`,
                subTitle: "副标题",
                desc: "描述",
                songCount: 5,
            }


            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    quality: [
                        {
                            package: "xyz.yhsj.demo",
                            id: `范类型id，可以字符串，可以集合${index}`,
                            title: "测试音质",
                            quality: 320,
                            size: 112200,
                        }
                    ],
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `标题${index}`,
                    subTitle: "副标题",
                    vip: index % 2 === 0 ? 0 : 1,
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],
                    album: {
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "专辑",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    },
                };
            });

            newPlaylist['songs'] = newArray

            return {
                code: 200,
                msg: '操作成功',
                data: newPlaylist,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        }
    },
    album: {
        type: function albumType() {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    title: "类型标题",
                    subType: [...Array(5)].map(function (_, index) {
                        return {
                            package: 'xyz.yhsj.demo',
                            id: "id",
                            title: "子类型标题",
                        };
                    })
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                //没有返回[]即可
                data: newArray
            };
        },
        list: function albumList(type, page = 0, size = 20) {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `专辑${index}`,
                    subTitle: "副标题",
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: "歌手id",
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        },
        info: function albumInfo(album, page = 0, size = 20) {


            const newAlbum =
                {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `专辑`,
                    subTitle: "副标题",
                    desc: "描述",
                    publishDate: "发布时间",
                    songCount: 5,
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: "歌手id",
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],


                }
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    quality: [
                        {
                            package: "xyz.yhsj.demo",
                            id: `范类型id，可以字符串，可以集合${index}`,
                            title: "测试音质",
                            quality: 320,
                            size: 112200,
                        }
                    ],
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `标题${index}`,
                    subTitle: "副标题",
                    vip: index % 2 === 0 ? 0 : 1,
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],
                    album: {
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "专辑",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
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

        },
    },
    //这里实现可以设置首页数据
    rec: {
        playlist: function playListRec() {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `歌单${index}`,
                    subTitle: "副标题",
                    desc: "描述",
                    songCount: 5,
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        },


        album: function albumRec() {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `专辑${index}`,
                    subTitle: "副标题",
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: "歌手id",
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        },
        song: function songRec() {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    quality: [
                        {
                            package: "xyz.yhsj.demo",
                            id: "范类型id，可以字符串，可以集合",
                            title: "测试音质",
                            quality: 320,
                            size: 112200,
                        }
                    ],
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `标题${index}`,
                    subTitle: "副标题",
                    vip: index % 2 === 0 ? 0 : 1,
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],
                    album: {
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "专辑",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    },
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        }
    },
    rank: {
        list: function rankList() {


            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: "xyz.yhsj.demo",
                    id: `范类型id，可以字符串，可以集合${index}`,
                    title: "榜单标题",
                    rankList: [...Array(5)].map(function (_, index) {
                        return {
                            package: 'xyz.yhsj.demo',
                            id: `范类型id，可以字符串，可以集合${index}`,
                            title: "榜单标题",
                            pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                        };
                    })
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,

            };


        },
        info: function rankInfo(rank, page = 0, size = 20) {

            const newAlbum = {
                package: 'xyz.yhsj.demo',
                id: `范类型id，可以字符串，可以集合`,
                pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                title: `榜单`,
                desc: "描述",
                songCount: 5,
            }
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    quality: [
                        {
                            package: "xyz.yhsj.demo",
                            id: `范类型id，可以字符串，可以集合${index}`,
                            title: "测试音质",
                            quality: 320,
                            size: 112200,
                        }
                    ],
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `标题${index}`,
                    subTitle: "副标题",
                    vip: index % 2 === 0 ? 0 : 1,
                    artist: [{
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "歌手标题",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                    }],
                    album: {
                        package: "xyz.yhsj.demo",
                        id: `范类型id，可以字符串，可以集合${index}`,
                        title: "专辑",
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
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
        }
    },
    artist: {
        type: function artistType() {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    title: "类型标题",
                    subType: [...Array(5)].map(function (_, index) {
                        return {
                            package: 'xyz.yhsj.demo',
                            id: "id",
                            title: "子类型标题",
                        };
                    })
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                //没有返回[]即可
                data: newArray
            };
        },
        list: function artistList(type, page = 0, size = 20) {
            const newArray = [...Array(5)].map(function (_, index) {
                return {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `歌手${index}`
                };
            });
            return {
                code: 200,
                msg: '操作成功',
                data: newArray,
                page: {
                    first: parseInt(page) === 0,
                    last: true,
                    page: 0,
                    size: 1,
                    number: newArray.length,
                    totalPages: 1,
                    totalSize: 5
                }
            };
        },
        info: function artistInfo(artist, page = 0, size = 20) {
            //这个方法暂时没用到
            return {
                code: 200,
                msg: '操作成功',
                data: {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合${index}`,
                    pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                    title: `歌手${index}`
                },
            };

        },
        detail: {
            song: function artistSong(artist, page = 0, size = 20) {
                const newArray = [...Array(5)].map(function (_, index) {
                    return {
                        package: 'xyz.yhsj.demo',
                        id: `范类型id，可以字符串，可以集合${index}`,
                        quality: [
                            {
                                package: "xyz.yhsj.demo",
                                id: "范类型id，可以字符串，可以集合",
                                title: "测试音质",
                                quality: 320,
                                size: 112200,
                            }
                        ],
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                        title: `标题${index}`,
                        subTitle: "副标题",
                        vip: index % 2 === 0 ? 0 : 1,
                        artist: [{
                            package: "xyz.yhsj.demo",
                            id: `范类型id，可以字符串，可以集合${index}`,
                            title: "歌手标题",
                            pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                        }],
                        album: {
                            package: "xyz.yhsj.demo",
                            id: `范类型id，可以字符串，可以集合${index}`,
                            title: "专辑",
                            pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                        },
                    };
                });
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray,
                    page: {
                        first: parseInt(page) === 0,
                        last: true,
                        page: 0,
                        size: 1,
                        number: newArray.length,
                        totalPages: 1,
                        totalSize: 5
                    }
                };
            },
            album: function artistAlbum(artist, page = 0, size = 20) {

                const newArray = [...Array(5)].map(function (_, index) {
                    return {
                        package: 'xyz.yhsj.demo',
                        id: `范类型id，可以字符串，可以集合${index}`,
                        pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                        title: `专辑${index}`,
                        subTitle: "副标题",
                        artist: [{
                            package: "xyz.yhsj.demo",
                            id: "歌手id",
                            title: "歌手标题",
                            pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`
                        }],
                    };
                });
                return {
                    code: 200,
                    msg: '操作成功',
                    data: newArray,
                    page: {
                        first: parseInt(page) === 0,
                        last: true,
                        page: 0,
                        size: 1,
                        number: newArray.length,
                        totalPages: 1,
                        totalSize: 5
                    }
                };
            },
        }

    },
    parse: {
        playlist: function parsePlayList(url) {
            const newPlaylist = {
                package: 'xyz.yhsj.demo',
                id: `范类型id，可以字符串，可以集合`,
                pic: `https://new.myfreemp3juices.cc/favicon-32x32.png`,
                title: `歌单`,
                subTitle: "副标题",
                desc: "描述",
                songCount: 5,
            }

            return {
                code: 200,
                msg: '操作成功',
                data: newPlaylist
            };

        }
    }
    ,
    user: {
        info: async function () {
            //这个方法需要和下面refresh同时存在，refresh可以没有具体功能，返回成功即可
            return {
                code: 200,
                msg: '操作成功',
                data: {
                    package: 'xyz.yhsj.demo',
                    id: `范类型id，可以字符串，可以集合`,
                    name: "测试用户",
                    pic: "https://new.myfreemp3juices.cc/favicon-32x32.png",
                    vipEndTime: "2024-01-01",
                    vip: 1,
                    login: 1
                }
            };
        }
        ,
        refresh: async function () {
            //获取cookie
            let cookie = await getStorage("cookie");
            //自己刷新cookie
            //保存cookie
            setStorage("cookie", cookie);
            return {
                code: 200,
                msg: '操作成功',
                data: null
            };

        }
    }
}
true