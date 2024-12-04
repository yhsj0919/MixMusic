// ==MixMusicPlugin==
// @name         酷我音乐
// @site         kuwo
// @package      xyz.yhsj.kuwo
// @version      0.0.1
// @versionCode  1
// @author       永恒瞬间
// @icon         https://kuwo.cn/favicon.ico
// @webSite      https://kuwo.cn
// @updateUrl    https://kuwo.cn
// @desc         官方插件
// ==/MixMusicPlugin==


const headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0",
    "Cookie": "",
    "Referer": "https://kuwo.cn",
}

const music = {
    // type 0:单曲, 1:相关歌手,2:专辑,3:歌单,4:MV,7:歌词,8:用户
    search: {
        music: async function (key, page = 0, size = 20) {
            // 定义查询参数
            const params = {
                "vipver": "1",
                "ft": "music",
                "encoding": "utf8",
                "mobi": "1",
                "all": key,
                "pn": parseInt(page),
                "rn": size,
            }
            console.log(new Date());
            console.log(encryptQuery("user=0&android_id=0&prod=kwplayer_ar_5.1.0.0_B&corp=kuwo&newver=3&vipver=5.1.0.0&source=kwplayer_ar_5.1.0.0_B_jiakong_vh.apk&p2p=1&notrace=0&type=convert_url2&br=320kmp3&format=flac|mp3|aac&sig=0&rid=226543302&priority=bitrate&loginUid=0&network=WIFI&loginSid=0&mode=download"))
            console.log(new Date());

            return axios.get('http://www.kuwo.cn/search/searchMusicBykeyWord', {
                headers: headers, params: params,
            }).then(function (data) {

                const respData = data.data

                console.log(respData)


                if (respData["code"] !== 0) {
                    return {
                        code: 500, msg: '请求失败', data: null
                    };
                }


                const newArray = respData["req"]["data"]["body"]["song"]["list"].map(function (element) {
                    return {
                        package: 'xyz.yhsj.qq',
                        id: {
                            id: element["id"], mid: element["mid"], mediaId: element["file"]["media_mid"]
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
                    code: 200, msg: '操作成功', data: newArray, page: {
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
    },
}
//==========================KwDES加密算法 https://github.com/UnblockNeteaseMusic/server ==============================
/*
	Thanks to
	https://github.com/XuShaohua/kwplayer/blob/master/kuwo/DES.py
	https://github.com/Levi233/MusicPlayer/blob/master/app/src/main/java/com/chenhao/musicplayer/utils/crypt/KuwoDES.java
*/

class Long {
    constructor(n) {
        this.bN = bigInt(n);
        this.low = Number(this.bN);
    }

    valueOf() {
        return this.bN.valueOf();
    }

    toString() {
        return this.bN.toString();
    }

    not() {
        return new Long(this.bN.not());
    }

    isNegative() {
        return this.bN < 0;
    }

    or(x) {
        return new Long(this.bN.or(x instanceof Long ? x.bN : bigInt(x)));
    }

    and(x) {
        return new Long(this.bN.and(x instanceof Long ? x.bN : bigInt(x)));
    }

    xor(x) {
        return new Long(this.bN.xor(x instanceof Long ? x.bN : bigInt(x)));
    }

    equals(x) {
        return new Long(this.bN.equals(x instanceof Long ? x.bN : bigInt(x)));
    }

    multiply(x) {
        return new Long(this.bN.multiply(x instanceof Long ? x.bN : bigInt(x)));
    }

    shiftLeft(x) {
        return new Long(this.bN.shiftLeft(x instanceof Long ? x.bN : bigInt(x)));
    }

    shiftRight(x) {
        return new Long(this.bN.shiftRight(x instanceof Long ? x.bN : bigInt(x)));
    }
}

const range = (n) => Array.from(new Array(n).keys());
const power = (base, index) => Array(index)
    .fill(null)
    .reduce((result) => result.multiply(base), new Long(1));
const LongArray = (...array) => array.map((n) => (n === -1 ? new Long(-1, -1) : new Long(n)));

// EXPANSION
const arrayE = LongArray(31, 0, 1, 2, 3, 4, -1, -1, 3, 4, 5, 6, 7, 8, -1, -1, 7, 8, 9, 10, 11, 12, -1, -1, 11, 12, 13, 14, 15, 16, -1, -1, 15, 16, 17, 18, 19, 20, -1, -1, 19, 20, 21, 22, 23, 24, -1, -1, 23, 24, 25, 26, 27, 28, -1, -1, 27, 28, 29, 30, 31, 30, -1, -1);

// INITIAL_PERMUTATION
const arrayIP = LongArray(57, 49, 41, 33, 25, 17, 9, 1, 59, 51, 43, 35, 27, 19, 11, 3, 61, 53, 45, 37, 29, 21, 13, 5, 63, 55, 47, 39, 31, 23, 15, 7, 56, 48, 40, 32, 24, 16, 8, 0, 58, 50, 42, 34, 26, 18, 10, 2, 60, 52, 44, 36, 28, 20, 12, 4, 62, 54, 46, 38, 30, 22, 14, 6);

// INVERSE_PERMUTATION
const arrayIP_1 = LongArray(39, 7, 47, 15, 55, 23, 63, 31, 38, 6, 46, 14, 54, 22, 62, 30, 37, 5, 45, 13, 53, 21, 61, 29, 36, 4, 44, 12, 52, 20, 60, 28, 35, 3, 43, 11, 51, 19, 59, 27, 34, 2, 42, 10, 50, 18, 58, 26, 33, 1, 41, 9, 49, 17, 57, 25, 32, 0, 40, 8, 48, 16, 56, 24);

// ROTATES
const arrayLs = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];
const arrayLsMask = LongArray(0, 0x100001, 0x300003);
const arrayMask = range(64).map((n) => power(2, n));
arrayMask[arrayMask.length - 1] = arrayMask[arrayMask.length - 1].multiply(-1);

// PERMUTATION
const arrayP = LongArray(15, 6, 19, 20, 28, 11, 27, 16, 0, 14, 22, 25, 4, 17, 30, 9, 1, 7, 23, 13, 31, 26, 2, 8, 18, 12, 29, 5, 21, 10, 3, 24);

// PERMUTED_CHOICE1
const arrayPC_1 = LongArray(56, 48, 40, 32, 24, 16, 8, 0, 57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2, 59, 51, 43, 35, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 60, 52, 44, 36, 28, 20, 12, 4, 27, 19, 11, 3);

// PERMUTED_CHOICE2
const arrayPC_2 = LongArray(13, 16, 10, 23, 0, 4, -1, -1, 2, 27, 14, 5, 20, 9, -1, -1, 22, 18, 11, 3, 25, 7, -1, -1, 15, 6, 26, 19, 12, 1, -1, -1, 40, 51, 30, 36, 46, 54, -1, -1, 29, 39, 50, 44, 32, 47, -1, -1, 43, 48, 38, 55, 33, 52, -1, -1, 45, 41, 49, 35, 28, 31, -1, -1);

const matrixNSBox = [[14, 4, 3, 15, 2, 13, 5, 3, 13, 14, 6, 9, 11, 2, 0, 5, 4, 1, 10, 12, 15, 6, 9, 10, 1, 8, 12, 7, 8, 11, 7, 0, 0, 15, 10, 5, 14, 4, 9, 10, 7, 8, 12, 3, 13, 1, 3, 6, 15, 12, 6, 11, 2, 9, 5, 0, 4, 2, 11, 14, 1, 7, 8, 13,], [15, 0, 9, 5, 6, 10, 12, 9, 8, 7, 2, 12, 3, 13, 5, 2, 1, 14, 7, 8, 11, 4, 0, 3, 14, 11, 13, 6, 4, 1, 10, 15, 3, 13, 12, 11, 15, 3, 6, 0, 4, 10, 1, 7, 8, 4, 11, 14, 13, 8, 0, 6, 2, 15, 9, 5, 7, 1, 10, 12, 14, 2, 5, 9,], [10, 13, 1, 11, 6, 8, 11, 5, 9, 4, 12, 2, 15, 3, 2, 14, 0, 6, 13, 1, 3, 15, 4, 10, 14, 9, 7, 12, 5, 0, 8, 7, 13, 1, 2, 4, 3, 6, 12, 11, 0, 13, 5, 14, 6, 8, 15, 2, 7, 10, 8, 15, 4, 9, 11, 5, 9, 0, 14, 3, 10, 7, 1, 12,], [7, 10, 1, 15, 0, 12, 11, 5, 14, 9, 8, 3, 9, 7, 4, 8, 13, 6, 2, 1, 6, 11, 12, 2, 3, 0, 5, 14, 10, 13, 15, 4, 13, 3, 4, 9, 6, 10, 1, 12, 11, 0, 2, 5, 0, 13, 14, 2, 8, 15, 7, 4, 15, 1, 10, 7, 5, 6, 12, 11, 3, 8, 9, 14,], [2, 4, 8, 15, 7, 10, 13, 6, 4, 1, 3, 12, 11, 7, 14, 0, 12, 2, 5, 9, 10, 13, 0, 3, 1, 11, 15, 5, 6, 8, 9, 14, 14, 11, 5, 6, 4, 1, 3, 10, 2, 12, 15, 0, 13, 2, 8, 5, 11, 8, 0, 15, 7, 14, 9, 4, 12, 7, 10, 9, 1, 13, 6, 3,], [12, 9, 0, 7, 9, 2, 14, 1, 10, 15, 3, 4, 6, 12, 5, 11, 1, 14, 13, 0, 2, 8, 7, 13, 15, 5, 4, 10, 8, 3, 11, 6, 10, 4, 6, 11, 7, 9, 0, 6, 4, 2, 13, 1, 9, 15, 3, 8, 15, 3, 1, 14, 12, 5, 11, 0, 2, 12, 14, 7, 5, 10, 8, 13,], [4, 1, 3, 10, 15, 12, 5, 0, 2, 11, 9, 6, 8, 7, 6, 9, 11, 4, 12, 15, 0, 3, 10, 5, 14, 13, 7, 8, 13, 14, 1, 2, 13, 6, 14, 9, 4, 1, 2, 14, 11, 13, 5, 0, 1, 10, 8, 3, 0, 11, 3, 5, 9, 4, 15, 2, 7, 8, 12, 15, 10, 7, 6, 12,], [13, 7, 10, 0, 6, 9, 5, 15, 8, 4, 3, 10, 11, 14, 12, 5, 2, 11, 9, 6, 15, 12, 0, 3, 4, 1, 14, 13, 1, 2, 7, 8, 1, 2, 12, 15, 10, 4, 0, 3, 13, 14, 6, 9, 7, 8, 9, 6, 15, 1, 5, 12, 3, 10, 14, 5, 8, 7, 11, 0, 4, 13, 2, 11,],];

const bitTransform = (arrInt, n, l) => {
    let l2 = new Long(0);
    range(n).forEach((i) => {
        if (arrInt[i].isNegative() || (l.and(arrayMask[arrInt[i]])).valueOf() === 0) return
        l2 = l2.or(arrayMask[i]);
    });
    return l2;
};

const DES64 = (longs, l) => {
    const pR = range(8).map(() => new Long(0));
    const pSource = [new Long(0), new Long(0)];
    let L = new Long(0);
    let R = new Long(0);
    let out = bitTransform(arrayIP, 64, l);
    pSource[0] = out.and(0xffffffff);
    pSource[1] = out.and(-4294967296).shiftRight(32);

    range(16).forEach((i) => {
        let SOut = new Long(0);

        R = new Long(pSource[1]);
        R = bitTransform(arrayE, 64, R);
        R = R.xor(longs[i]);
        range(8).forEach((j) => {
            pR[j] = R.shiftRight(j * 8).and(255);
        });
        range(8)
            .reverse()
            .forEach((sbi) => {
                SOut = SOut.shiftLeft(4).or(matrixNSBox[sbi][pR[sbi]]);
            });
        R = bitTransform(arrayP, 32, SOut);
        L = new Long(pSource[0]);
        pSource[0] = new Long(pSource[1]);
        pSource[1] = L.xor(R);
    });
    pSource.reverse();
    out = pSource[1]
        .shiftLeft(32)
        .and(-4294967296)
        .or(pSource[0].and(0xffffffff));
    out = bitTransform(arrayIP_1, 64, out);
    return out;
};

const subKeys = (l, longs, n) => {
    // long, long[], int
    let l2 = bitTransform(arrayPC_1, 56, l);
    range(16).forEach((i) => {
        l2 = l2
            .and(arrayLsMask[arrayLs[i]])
            .shiftLeft(28 - arrayLs[i])
            .or(l2.and(arrayLsMask[arrayLs[i]].not()).shiftRight(arrayLs[i]));
        longs[i] = bitTransform(arrayPC_2, 64, l2);
    });
    if (n === 1) {
        range(8).forEach((j) => {
            [longs[j], longs[15 - j]] = [longs[15 - j], longs[j]];
        });
    }
};

const crypt = (msg, key, mode) => {
    // 处理密钥块
    let l = new Long(0);
    range(8).forEach((i) => {
        l = new Long(key[i])
            .shiftLeft(i * 8)
            .or(l);
    });

    const j = Math.floor(msg.length / 8);
    // arrLong1 存放的是转换后的密钥块, 在解密时只需要把这个密钥块反转就行了
    const arrLong1 = range(16).map(() => new Long(0));
    subKeys(l, arrLong1, mode);

    // arrLong2 存放的是前部分的明文
    const arrLong2 = range(j).map(() => new Long(0));

    range(j).forEach((m) => {
        range(8).forEach((n) => {
            arrLong2[m] = new Long(msg[n + m * 8])
                .shiftLeft(n * 8)
                .or(arrLong2[m]);
        });
    });

    // 用于存放密文
    const arrLong3 = range(Math.floor((1 + 8 * (j + 1)) / 8)).map(() => new Long(0));

    // 计算前部的数据块(除了最后一部分)
    range(j).forEach((i1) => {
        arrLong3[i1] = DES64(arrLong1, arrLong2[i1]);
    });

    // 保存多出来的字节
    const arrByte1 = msg.slice(j * 8);
    let l2 = new Long(0);

    range(msg.length % 8).forEach((i1) => {
        l2 = new Long(arrByte1[i1])
            .shiftLeft(i1 * 8)
            .or(l2);
    });

    // 计算多出的那一位(最后一位)
    if (arrByte1.length || mode === 0) arrLong3[j] = DES64(arrLong1, l2); // 解密不需要

    // 将密文转为字节型
    const arrByte2 = range(8 * arrLong3.length).map(() => 0);
    let i4 = 0;
    arrLong3.forEach((l3) => {
        range(8).forEach((i6) => {
            arrByte2[i4] = l3.shiftRight(i6 * 8).and(255).low;
            i4 += 1;
        });
    });
    return numberArrayToUint8Array(arrByte2);
};


function numberArrayToUint8Array(numbers) {
    // Ensure that all numbers are in the range 0-255
    const validNumbers = numbers.map(num => Math.max(0, Math.min(255, num)));
    return new Uint8Array(validNumbers);
}

function stringToUint8Array(str) {
    const utf8 = [];
    for (let i = 0; i < str.length; i++) {
        const codePoint = str.charCodeAt(i);
        if (codePoint <= 0x7f) {
            utf8.push(codePoint);
        } else if (codePoint <= 0x7ff) {
            utf8.push(0xc0 | (codePoint >> 6));
            utf8.push(0x80 | (codePoint & 0x3f));
        } else if (codePoint <= 0xffff) {
            utf8.push(0xe0 | (codePoint >> 12));
            utf8.push(0x80 | ((codePoint >> 6) & 0x3f));
            utf8.push(0x80 | (codePoint & 0x3f));
        } else {
            utf8.push(0xf0 | (codePoint >> 18));
            utf8.push(0x80 | ((codePoint >> 12) & 0x3f));
            utf8.push(0x80 | ((codePoint >> 6) & 0x3f));
            utf8.push(0x80 | (codePoint & 0x3f));
        }
    }
    return new Uint8Array(utf8);
}


const SECRET_KEY = stringToUint8Array('ylzsxkwm');

const encrypt = (msg) => crypt(msg, SECRET_KEY, 0);
const decrypt = (msg) => crypt(msg, SECRET_KEY, 1);
const encryptQuery = (query) => base64.fromByteArray(encrypt(stringToUint8Array(query)));

true