import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {releaseConfig, releaseNotes, prepare, packageAndroid, packageWindows, checksums, publish} from './release.mjs';

const installerTemplate = new URL('../windows/packaging/exe/setup.iss', import.meta.url);
const installerIcon = new URL('../windows/runner/resources/app_icon.ico', import.meta.url);
const installerChinese = new URL('../windows/packaging/exe/ChineseSimplified.isl', import.meta.url);

const inputs = {release_type: 'stable', platforms: 'android,windows'};
const pubspec = 'name: mix_music\nversion: 0.1.0+1\n';

function fixture(t) {
    const previous = process.cwd();
    const parent = path.join(previous, '.dart_tool');
    fs.mkdirSync(parent, {recursive: true});
    const directory = fs.mkdtempSync(path.join(parent, 'release-test-'));
    process.chdir(directory);
    t.after(() => {
        process.chdir(previous);
        assert.equal(path.dirname(path.resolve(directory)), path.resolve(parent));
        fs.rmSync(directory, {recursive: true, force: true});
    });
    return directory;
}

function metadata(config = {}) {
    const value = {...releaseConfig(inputs, pubspec, 20), sha: 'a'.repeat(40), flutter: '3.47.7', ...config};
    fs.mkdirSync('build/release-metadata', {recursive: true});
    fs.writeFileSync('build/release-metadata/release.json', JSON.stringify(value));
    fs.writeFileSync('build/release-metadata/notes.md', '中文更新说明');
    fs.mkdirSync('dist');
    fs.writeFileSync(`dist/MixMusic-windows-x64-${value.tag}.zip`, 'abc');
    return value;
}

test('version, build number and prerelease type match package naming', () => {
    const stable = releaseConfig(inputs, pubspec, 20);
    assert.equal(stable.version, '0.1.0');
    assert.equal(stable.build, '20');
    assert.equal(stable.tag, 'v0.1.0');
    assert.deepEqual(stable.matrix.include.map(item => item.platform), ['android', 'windows']);
    const preview = releaseConfig({...inputs, release_type: 'prerelease', version: 'v0.2.0'}, pubspec, 21);
    assert.equal(preview.tag, 'v0.2.0-beta.21');
    assert.equal(preview.prerelease, true);
    assert.equal(releaseConfig({...inputs, publish: 'false'}, pubspec, 1).publish, false);
});

test('invalid version and release combinations fail before building', () => {
    for (const version of ['1.2', '1.2.3+99', '1.02.3', '1.2.3-beta.01', '$(command)', '../1.2.3']) {
        assert.throws(() => releaseConfig({...inputs, version}, pubspec, 1));
    }
    assert.throws(() => releaseConfig({...inputs, version: '1.2.3-beta.1'}, pubspec, 1));
    assert.throws(() => releaseConfig({...inputs, build_number: '-1'}, pubspec, 1));
    assert.throws(() => releaseConfig({...inputs, platforms: 'unknown'}, pubspec, 1));
    assert.throws(() => releaseConfig({...inputs, build_number: '65536'}, pubspec, 1), /65535/);
});

test('Chinese notes use Unreleased and append manual notes, excluding old versions', () => {
    const config = {...releaseConfig(inputs, pubspec, 20), sha: 'abc', flutter: '3.47.7'};
    const notes = releaseNotes('# 日志\n\n## [Unreleased]\n\n### 修复\n- 恢复歌词\n\n## [0.0.1]\n- 旧内容\n', '补充：修复目录授权', config);
    assert.match(notes, /恢复歌词/);
    assert.match(notes, /修复目录授权/);
    assert.doesNotMatch(notes, /旧内容/);
    assert.match(notes, /构建号：20/);
});

test('Android packages use explicit system, architecture and release tag', t => {
    const root = fixture(t);
    const source = 'build/app/outputs/flutter-apk';
    fs.mkdirSync(source, {recursive: true});
    for (const abi of ['arm64-v8a', 'armeabi-v7a', 'x86_64']) fs.writeFileSync(`${source}/app-${abi}-release.apk`, abi);
    packageAndroid(root, releaseConfig(inputs, pubspec, 20));
    assert.deepEqual(fs.readdirSync('dist').sort(), ['MixMusic-android-arm64-v0.1.0.apk', 'MixMusic-android-armv7-v0.1.0.apk', 'MixMusic-android-x64-v0.1.0.apk']);
    assert.equal(fs.readFileSync('dist/MixMusic-android-arm64-v0.1.0.apk', 'utf8'), 'arm64-v8a');
});

test('checksum file uses standard sha256sum syntax and requires packages', t => {
    fixture(t);
    fs.mkdirSync('dist');
    assert.throws(() => checksums('dist'));
    fs.writeFileSync('dist/MixMusic-windows-x64-v0.1.0.zip', 'abc');
    assert.equal(checksums('dist').length, 2);
    assert.equal(fs.readFileSync('dist/SHA256SUMS', 'utf8'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad  MixMusic-windows-x64-v0.1.0.zip\n');
});

test('EXE installers are included in checksums and publication assets', t => {
    fixture(t);
    fs.mkdirSync('dist');
    fs.writeFileSync('dist/MixMusic-windows-x64-v0.2.0-setup.exe', 'abc');
    assert.deepEqual(checksums('dist'), ['MixMusic-windows-x64-v0.2.0-setup.exe', 'SHA256SUMS']);
});

const iscc = process.env.INNO_SETUP_COMPILER || 'C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe';
test('Inno Setup compiles actual installer script for a prerelease fixture', {skip: process.platform !== 'win32' || !fs.existsSync(iscc)}, t => {
    const root = fixture(t);
    const config = metadata({version: '0.2.0-beta.1', tag: 'v0.2.0-beta.1', build: '21'});
    const source = 'build/windows/x64/runner/Release';
    fs.mkdirSync(source, {recursive: true});
    fs.writeFileSync(`${source}/mix_music.exe`, 'test fixture only');
    fs.mkdirSync('windows/packaging/exe', {recursive: true});
    fs.mkdirSync('windows/runner/resources', {recursive: true});
    fs.copyFileSync(installerTemplate, 'windows/packaging/exe/setup.iss');
    fs.copyFileSync(installerChinese, 'windows/packaging/exe/ChineseSimplified.isl');
    fs.copyFileSync(installerIcon, 'windows/runner/resources/app_icon.ico');
    const file = packageWindows(root, config, iscc);
    assert.equal(path.basename(file), 'MixMusic-windows-x64-v0.2.0-beta.1-setup.exe');
    assert.equal(fs.readFileSync(file).subarray(0, 2).toString(), 'MZ');
});

test('prepare fixes all dependency revisions without publishing in build-only mode', async t => {
    fixture(t);
    fs.writeFileSync('pubspec.yaml', pubspec);
    fs.writeFileSync('CHANGELOG.md', '## [Unreleased]\n- 测试更新\n');
    const revisions = [];
    const outputs = {};
    const github = {rest: {repos: {getCommit: async data => {
        revisions.push(data);
        return {data: {sha: 'a'.repeat(40)}};
    }}}};
    await prepare({github, context: {payload: {inputs: {...inputs, platforms: 'windows', publish: 'false'}}, runNumber: 20, sha: 'b'.repeat(40)}, core: {setOutput: (name, value) => outputs[name] = value}});
    assert.equal(revisions.length, 6);
    assert.equal(JSON.parse(outputs.dependencies).quickjs.ref, 'a'.repeat(40));
    assert.equal(JSON.parse(outputs.matrix).include[0].platform, 'windows');
    assert.equal(outputs.publish, false);
    assert.match(fs.readFileSync('build/release-metadata/notes.md', 'utf8'), /测试更新/);
});

test('existing tag fails before checking out or publishing anything', async t => {
    fixture(t);
    fs.writeFileSync('pubspec.yaml', pubspec);
    const github = {rest: {git: {getRef: async () => ({data: {ref: 'refs/tags/v0.1.0'}})}}};
    await assert.rejects(prepare({github, context: {
        payload: {inputs: {...inputs, platforms: 'windows'}}, runNumber: 20, sha: 'a'.repeat(40), repo: {owner: 'test', repo: 'test'},
    }, core: {}}), /标签 v0.1.0 已存在/);
    assert.equal(fs.existsSync('build/release-metadata/release.json'), false);
});

for (const preview of [false, true]) {
    test(`${preview ? 'preview' : 'stable'} publishes only after every asset, with correct Latest flag`, async t => {
        fixture(t);
        const config = metadata({prerelease: preview});
        const installer = `MixMusic-windows-x64-${config.tag}-setup.exe`;
        fs.writeFileSync(path.join('dist', installer), 'installer fixture');
        const events = [];
        const github = {rest: {repos: {
            createRelease: async data => { events.push(['create', data]); return {data: {id: 1, html_url: 'https://github.com/release'}}; },
            uploadReleaseAsset: async data => events.push(['upload', data.name]),
            updateRelease: async data => events.push(['publish', data]),
        }}};
        const summary = {addHeading: () => summary, addLink: () => summary, write: async () => {}};
        await publish({github, context: {repo: {owner: 'test', repo: 'test'}}, core: {notice: () => {}, summary}});
        assert.equal(events[0][1].draft, true);
        assert.equal(events[0][1].target_commitish, config.sha);
        assert.equal(events[0][1].body, '中文更新说明');
        assert.deepEqual(events.map(event => event[0]), ['create', 'upload', 'upload', 'upload', 'publish']);
        assert.ok(events.some(event => event[0] === 'upload' && event[1] === installer));
        assert.equal(events.at(-1)[1].make_latest, preview ? 'false' : 'true');
        assert.equal(events.at(-1)[1].prerelease, preview);
    });
}

test('failed asset upload leaves draft, never exposing partial release', async t => {
    fixture(t);
    metadata();
    let published = false;
    const github = {rest: {repos: {
        createRelease: async () => ({data: {id: 1}}),
        uploadReleaseAsset: async () => { throw new Error('upload failed'); },
        updateRelease: async () => published = true,
    }}};
    await assert.rejects(publish({github, context: {repo: {owner: 'test', repo: 'test'}}, core: {}}), /upload failed/);
    assert.equal(published, false);
});
