import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const metadataPath = 'build/release-metadata/release.json';

export function releaseConfig(inputs, pubspec, runNumber) {
    const declared = pubspec.match(/^version:\s*([^\s#]+)/m)?.[1];
    let version = (inputs.version?.trim() || declared?.split('+')[0] || '').replace(/^v/, '');
    const build = String(inputs.build_number?.trim() || runNumber);
    if (!/^[1-9]\d{0,7}$/.test(build)) throw new Error('构建号必须为 1 至 99999999 的整数');
    const prerelease = inputs.release_type === 'prerelease';
    if (!['stable', 'prerelease'].includes(inputs.release_type)) throw new Error('请选择正式发布或预发布');
    if (prerelease && !version.includes('-')) version += `-beta.${build}`;
    const match = version.match(/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/);
    if (!match || match[4]?.split('.').some(value => /^0\d+$/.test(value))) throw new Error('版本号应为 0.2.0 或 0.2.0-beta.1，不带构建号');
    if (!prerelease && match[4]) throw new Error('正式发布不能使用 beta/rc 等预发行版本号');
    if (!['android,windows', 'android', 'windows'].includes(inputs.platforms)) throw new Error('构建平台无效');
    const platforms = inputs.platforms.split(',');
    if (platforms.includes('windows') && [match[1], match[2], match[3], build].some(value => Number(value) > 65535)) {
        throw new Error('Windows 的版本数字和构建号不能超过 65535');
    }
    return {
        version, build, tag: `v${version}`, prerelease,
        publish: inputs.publish !== false && inputs.publish !== 'false',
        matrix: {include: platforms.map(platform => ({platform, os: platform === 'android' ? 'ubuntu-24.04' : 'windows-2022'}))},
    };
}

export function releaseNotes(markdown, extra, config) {
    const section = markdown.match(/^##\s+\[Unreleased\][^\n]*\n([\s\S]*?)(?=^##\s|$(?![\s\S]))/m)?.[1]?.trim() || '';
    return [
        `# MixMusic ${config.tag}`,
        config.prerelease ? '预发布版本，用于功能验证。' : '正式发布版本。',
        section,
        extra?.trim(),
        `### 安装包\n按文件名中的系统和架构选择安装包；Windows 可使用 setup.exe 安装，或完整解压 ZIP 后运行 mix_music.exe。`,
        `### 构建信息\n- 版本：${config.version}\n- 构建号：${config.build}\n- 代码：${config.sha}\n- Flutter：${config.flutter}`,
    ].filter(Boolean).join('\n\n') + '\n';
}

export async function prepare({github, context, core}) {
    const inputs = context.payload.inputs;
    const config = releaseConfig(inputs, fs.readFileSync('pubspec.yaml', 'utf8'), context.runNumber);
    config.sha = context.sha;
    config.flutter = process.env.FLUTTER_VERSION;
    if (config.publish) {
        try {
            await github.rest.git.getRef({...context.repo, ref: `tags/${config.tag}`});
            throw new Error(`标签 ${config.tag} 已存在，请递增版本，不覆盖已有发布`);
        } catch (error) {
            if (error.status !== 404) throw error;
        }
    }
    if (config.matrix.include.some(item => item.platform === 'android')) {
        const required = ['ANDROID_KEYSTORE_BASE64', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD'];
        const missing = required.filter(name => !process.env[name]);
        if (missing.length) throw new Error(`请先配置 Android 固定签名 Secrets：${missing.join(', ')}`);
    }
    fs.mkdirSync(path.dirname(metadataPath), {recursive: true});
    fs.writeFileSync(metadataPath, JSON.stringify(config, null, 2) + '\n');
    const changelog = fs.readFileSync('CHANGELOG.md', 'utf8');
    fs.writeFileSync('build/release-metadata/notes.md', releaseNotes(changelog, inputs.notes, config));
    for (const name of ['version', 'build', 'tag', 'sha', 'matrix', 'publish']) {
        core.setOutput(name, typeof config[name] === 'object' ? JSON.stringify(config[name]) : config[name]);
    }
}

export function packageAndroid(root, config) {
    const output = path.join(root, 'dist');
    fs.mkdirSync(output, {recursive: true});
    for (const [abi, arch] of [['arm64-v8a', 'arm64'], ['armeabi-v7a', 'armv7'], ['x86_64', 'x64']]) {
        const source = path.join(root, 'build/app/outputs/flutter-apk', `app-${abi}-release.apk`);
        if (!fs.statSync(source).size) throw new Error(`安装包为空：${source}`);
        fs.copyFileSync(source, path.join(output, `MixMusic-android-${arch}-${config.tag}.apk`));
    }
}

export function packageWindows(root, config, compiler = process.env.INNO_SETUP_COMPILER || 'C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe') {
    const source = path.join(root, 'build/windows/x64/runner/Release');
    if (!fs.existsSync(path.join(source, 'mix_music.exe'))) throw new Error('缺少 Windows Release 构建产物');
    const output = path.join(root, 'dist');
    fs.mkdirSync(output, {recursive: true});
    execFileSync(compiler, [
        '/Qp', `/DAppVersion=${config.version}`, `/DAppNumericVersion=${config.version.split('-')[0]}.${config.build}`,
        `/DAppSourceDir=${source}`, `/O${output}`, `/FMixMusic-windows-x64-${config.tag}-setup`,
        path.join(root, 'windows/packaging/exe/setup.iss'),
    ], {stdio: 'inherit'});
    const installer = path.join(output, `MixMusic-windows-x64-${config.tag}-setup.exe`);
    if (!fs.statSync(installer).size) throw new Error('EXE 安装包为空');
    return installer;
}

export function checksums(directory) {
    const files = fs.readdirSync(directory).filter(name => /^MixMusic-.+\.(apk|zip|exe)$/.test(name)).sort();
    if (!files.length) throw new Error('没有找到待发布的安装包');
    const lines = files.map(name => `${crypto.createHash('sha256').update(fs.readFileSync(path.join(directory, name))).digest('hex')}  ${name}`);
    fs.writeFileSync(path.join(directory, 'SHA256SUMS'), lines.join('\n') + '\n');
    return [...files, 'SHA256SUMS'];
}

export async function publish({github, context, core}) {
    const config = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
    const directory = 'dist';
    const files = checksums(directory);
    const {data: release} = await github.rest.repos.createRelease({
        ...context.repo, tag_name: config.tag, target_commitish: config.sha,
        name: `MixMusic ${config.tag}`, draft: true, prerelease: config.prerelease,
        body: fs.readFileSync('build/release-metadata/notes.md', 'utf8'),
        generate_release_notes: true,
    });
    for (const name of files) {
        await github.rest.repos.uploadReleaseAsset({
            ...context.repo, release_id: release.id, name,
            data: fs.readFileSync(path.join(directory, name)),
        });
    }
    await github.rest.repos.updateRelease({
        ...context.repo, release_id: release.id, draft: false,
        prerelease: config.prerelease, make_latest: config.prerelease ? 'false' : 'true',
    });
    core.notice(`发布完成：${release.html_url}`);
    await core.summary.addHeading('发布完成').addLink(config.tag, release.html_url).write();
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
    const config = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
    if (process.argv[2] === 'android') packageAndroid(process.cwd(), config);
    else if (process.argv[2] === 'windows') packageWindows(process.cwd(), config);
    else throw new Error('未知打包命令');
}
