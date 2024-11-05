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
- [x] 搜索
- [x] 跨站点匹配
- [x] 歌手
- [x] 榜单
- [x] 新歌
- [x] 歌单导入
- [x] 首页自定义数据
- [ ] 协同播放(相同数据源的接口，比如官方和第三方，可以将官方交由第三方直接解析，或者交由本地匹配)
- [ ] MV
- [x] 登录(设置cookie)
- [ ] 音质选择
- [ ] 下载
- [ ] UI重制，现在UI看看就好，早晚都得换
- [ ] 评论(暂时的优先比较低)

## 笔记

#### 这一部分暂时在js框架中处理了

 ```
 ` 在js中属于特殊字符，替换为\\`
 \\在js中属于特殊字符，替换为\\\\
 ```

## 文档

### 内置模块

#### 其他必要模块请自行合并到插件内

```js
Axios
Crypto
HandlePromises
fetch
xhr
```

### 设置Cookie

#### 存储使用package作为键值，注意不要和其他插件相同

```js
//在插件中获取cookie，由于框架限制需要使用await
const cookie = await getCookie();

//在插件中保存cookie,以字符串形式保存,返回Boolean类型
setCookie(cookie);
```
