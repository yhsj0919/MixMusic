# MixMusic

一个插件化的音乐播放器

修改 Model 之后 运行 ```flutter pub run build_runner build --delete-conflicting-outputs```

## 说明

该软件不内置任何音源，一切播放能力基于js插件

该软件处于试验阶段，一切api都有可能改变

代码很垃圾，就实现了基本功能

## 已实现功能

- [x] 播放
- [x] 歌单分类，列表 ，详情
- [x] 专辑分类，列表，详情
- [x] 搜索，单曲，歌单，专辑，歌手
- [x] 跨站点匹配
- [x] 歌手，单曲，专辑
- [x] 榜单
- [x] 新歌
- [x] 歌单导入
- [x] 首页自定义数据
- [x] 登录(设置cookie)
- [x] 登录(手机验证码)
- [x] 登录后刷新cookie
- [x] 登录后获取用户信息
- [x] 登录后如果有VIP禁用匹配
- [x] 下载
- [x] MV
- [x] 手机UI

## 待实现功能

- [ ] 登录：密码，网页，扫码等
- [ ] 播放音质选择
- [ ] 歌词相关重制
- [ ] 桌面，平板，车机UI
- [ ] 评论(暂时的优先比较低)
- [ ] 协同播放(相同数据源的接口，比如官方和第三方，可以将官方交由第三方直接解析，或者交由本地匹配)
- [ ] 本地文件管理，本地匹配
- [ ] 登陆后的收藏，关注列表
- [ ] 本地跨平台歌单，收藏

## 笔记

#### 这一部分暂时在js框架中处理了

 ```
 ` 在js中属于特殊字符，替换为\\`
 \\在js中属于特殊字符，替换为\\\\
 ```

## 文档

### 插件系统

```
插件基于QuickJS，版本2021-03-07

```

### 内置模块

#### 其他必要模块请自行合并到插件内

```js
Axios
Crypto
HandlePromises
fetch
xhr
BigInteger
base64 - js
FastXmlParser
await rsaEncrypt(data, key, format) //返回字符串,format base16 默认,base64
await rsaDecrypt(data, key) //接收hex格式字符串，返回解密后字符串
await aesEncrypt(data, key, iv, format) //返回字符串,format base16 默认,base64
await aesDecrypt(data, key, iv) //接收hex格式字符串，返回解密后字符串
await md5(data)  //返回32位字符串
```

### 音质

```js
//由quality字段判断, flac以后再调整
//参考🐧的分级

//[
//     {quality: 24, q: "size_24aac", s: "C100", e: ".m4a"},
//     {quality: 48, q: "size_48aac", s: "C200", e: ".m4a"},
//     {quality: 96, q: "size_96aac", s: "C400", e: ".m4a"},
//     {quality: 128, q: "size_128mp3", s: "M500", e: ".mp3"},
//     {quality: 192, q: "size_192ogg", s: "O600", e: ".ogg"},
//     {quality: 192, q: "size_192aac", s: "C600", e: ".m4a"},
//     {quality: 320, q: "size_320mp3", s: "M800", e: ".mp3"},
//     {quality: 1000, q: "size_flac", s: "F000", e: ".flac"},
//     {quality: 1000, q: "size_ape", s: "A000", e: ".ape"},
//     {quality: 1000, q: "size_dts", s: "D00A", e: ".flac"},
//     {quality: 1000, q: "size_hires", s: "RS01", e: ".flac"},
// ];

//播放音质分级

//标准音质           128
//极高音质           320
//无损音质           1000
//Hi-Res/臻品        2000
//高清/超清          3000
//母带               4000

//其他音质不参与播放音质选择
//全景声             1100
//其他类似音质        1000-2000


```

### 设置Cookie

#### 存储使用package+key作为键值，注意不要和其他插件相同

```js
//在插件中获取值，由于框架限制需要使用await
const value = await getStorage(key);

//在插件中保存值,以字符串形式保存,返回Boolean类型
setStorage(key, value);
```
