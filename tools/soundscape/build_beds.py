#!/usr/bin/env python3
"""八經卦錄音音景：下載 CC0／公有領域錄音 → 柔化成「遠、柔、包覆」的音景 → 存成 App 資產與試聽檔。

用法（GitHub Actions 的 soundscape_beds.yml 也是跑這支）：
  python3 tools/soundscape/build_beds.py [--cache DIR] [--out assets/audio/beds] [--preview DIR]

需要 ffmpeg 與 numpy（不需要 scipy）。同樣的輸入一定產生同樣的輸出（固定亂數種子）。
處理流程與參數說明見 HANDOFF §0.3。
"""
import argparse, json, os, subprocess, time, urllib.parse, urllib.request
import numpy as np

SR = 11025          # 資產取樣率（單聲道 16-bit）；App 升頻到 22050
CLIP = 56.0         # 每卦存 56 秒（App 的 40／50 秒循環 + 3 秒交叉淡化都夠用）
PRE = 4.0           # 前面多處理 4 秒再丟掉，殘響與增益控制才不會從零開始

# 每卦的錄音與處理參數。
#  start：從原檔第幾秒開始取；shuffle：原檔太短時，把 4 秒小段隨機重排接成 60 秒（質地型聲音聽不出重複）
#  rms：最後的均方根音量（合成版主要音層約 0.06）；lp：低通頻率；wet：殘響比例（越大越遠）
#  ratio：瞬態壓縮比（越大越平）；ride：慢速音量平整程度（0＝不動，1＝完全拉平）
BEDS = {
    'qian': dict(title='Vento fisterra.ogg', start=110, rms=0.05, lp=2400, wet=0.55, ratio=3, ride=0.7),
    'kun': dict(title='Country night noise.ogg', shuffle=True, rms=0.045, lp=4200, wet=0.55, ratio=4, ride=0.6),
    'zhen': dict(title='Light Rain Distant Thunder July 5th 2016.wav', start=20, rms=0.06, lp=3800, wet=0.5, ratio=4, ride=0.5),
    'xun': dict(title='Killiney Hill Storm Floris 20250804 1537.ogg', start=6, rms=0.05, lp=3500, wet=0.5, ratio=4, ride=0.6),
    'kan': dict(title='Forest lawn creek.ogg', start=70, rms=0.055, lp=3800, wet=0.5, ratio=4, ride=0.5),
    'li': dict(title='Dry grass burning in open fireplace.ogg', shuffle=True, rms=0.04, lp=3800, wet=0.5, ratio=5, ride=0.5),
    'gen': dict(title='20090610 0 ambience.ogg', start=10, rms=0.045, lp=4500, wet=0.5, ratio=4, ride=0.5),
    'dui': dict(title='17650 thoschi issyk-kul.ogg', start=60, rms=0.055, lp=3600, wet=0.5, ratio=4, ride=0.6),
}
LABEL = {'qian': '乾・天', 'kun': '坤・地', 'zhen': '震・雷', 'xun': '巽・風', 'kan': '坎・水', 'li': '離・火', 'gen': '艮・山', 'dui': '兌・澤'}

UA = 'IchingCardsSoundscape/1.0 (https://github.com/lawrence124875/iching-cards)'


def http(url, tries=8):
    for i in range(tries):
        try:
            return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=120).read()
        except urllib.error.HTTPError as e:
            if e.code == 429 or e.code >= 500:
                time.sleep(4 * (i + 1))
                continue
            raise
    raise RuntimeError(f'下載失敗：{url}')


def fetch(title, cache):
    """回傳 (本機音檔路徑, 來源資訊)。先抓 Wikimedia 轉檔 mp3（原檔常回 429）。"""
    os.makedirs(cache, exist_ok=True)
    meta_path = os.path.join(cache, title + '.json')
    if os.path.exists(meta_path):
        meta = json.load(open(meta_path))
        if os.path.exists(meta['file']):
            return meta['file'], meta
    q = urllib.parse.urlencode(dict(action='query', titles='File:' + title, prop='imageinfo', format='json',
                                    iiprop='url|extmetadata', iiextmetadatafilter='LicenseShortName|Artist'))
    pg = next(iter(json.loads(http('https://commons.wikimedia.org/w/api.php?' + q))['query']['pages'].values()))
    ii = pg['imageinfo'][0]
    lic = ii['extmetadata']['LicenseShortName']['value']
    if lic not in ('CC0', 'Public domain'):
        raise SystemExit(f'{title}：授權是 {lic}，只能用 CC0／公有領域')
    url = ii['url'].split('?')[0]
    name = url.rsplit('/', 1)[1]
    a, b = url.split('/commons/')[1].split('/')[:2]
    tried = [] if name.endswith('.mp3') else [f'https://upload.wikimedia.org/wikipedia/commons/transcoded/{a}/{b}/{name}/{name}.mp3']
    for u in tried + [url]:
        try:
            data = http(u)
        except Exception:
            continue
        path = os.path.join(cache, name + ('.mp3' if u.endswith('.mp3') and not name.endswith('.mp3') else ''))
        open(path, 'wb').write(data)
        import re
        artist = re.sub('<[^>]+>', '', ii['extmetadata'].get('Artist', {}).get('value', '')).strip()
        meta = dict(file=path, title=title, license=lic, artist=artist,
                    page='https://commons.wikimedia.org/wiki/' + urllib.parse.quote('File:' + title.replace(' ', '_')))
        json.dump(meta, open(meta_path, 'w'), ensure_ascii=False)
        return path, meta
    raise RuntimeError(f'下載失敗：{title}')


def decode(path):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(SR), '-f', 'f32le', '-'],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)


def shuffle_extend(x, seconds, rng, grain=4.0, fade=1.0):
    """短錄音：隨機取 4 秒小段、1 秒等功率交叉淡化接起來，避免聽得出整段重複。"""
    g, f = int(grain * SR), int(fade * SR)
    out = np.zeros(int(seconds * SR) + g)
    w = np.sin(np.linspace(0, np.pi / 2, f))
    pos, last = 0, -1
    while pos < len(out) - g:
        while True:
            s = int(rng.integers(0, len(x) - g))
            if last < 0 or abs(s - last) > g:
                break
        seg = x[s:s + g].copy()
        if pos > 0:
            seg[:f] *= w
            out[pos:pos + f] *= w[::-1]
        out[pos:pos + g] += seg
        pos += g - f
        last = s
    return out[:int(seconds * SR)]


def spectral(x, hp=60.0, lp=4000.0, tilt=1.5):
    """零相位 FFT 濾波：60Hz 高通、柔和低通（4 階），再從 1kHz 起每八度 −tilt dB（空氣吸收，聲音變遠）。"""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR) + 1e-6
    h = 1 / np.sqrt(1 + (hp / f) ** 4) / np.sqrt(1 + (f / lp) ** 8)
    h *= 10 ** (-tilt * np.maximum(0, np.log2(f / 1000)) / 20)
    return np.fft.irfft(X * h, len(x))


def frames_rms(x, hop):
    n = len(x) // hop
    return np.sqrt(np.mean(x[:n * hop].reshape(n, hop) ** 2, axis=1) + 1e-12)


def smooth(v, k):
    if k < 2:
        return v
    w = np.hanning(k)
    w /= w.sum()
    return np.convolve(np.pad(v, (k, k), mode='edge'), w, mode='same')[k:-k]


def to_samples(g, hop, n):
    return np.interp(np.arange(n), np.arange(len(g)) * hop + hop / 2, g)


def tame(x, ratio=4.0, ride=0.5):
    """近距離瞬態壓下來（5 ms 框、往前看 30 ms），再把 3 秒尺度的忽大忽小部分拉平。"""
    hop = int(0.005 * SR)
    r = frames_rms(x, hop)
    ref = np.median(r)
    thr = 1.5 * ref
    g = np.minimum(1.0, (thr / r) ** (1 - 1 / ratio))
    g = np.minimum(g, np.minimum(1.0, 3 * ref / r))  # 超過中位數 3 倍一律壓到 3 倍
    # 往前往後各看 6 框取最小值（起音前就先降），再平滑
    k = 6
    gp = np.pad(g, k, mode='edge')
    g = np.min(np.stack([gp[i:i + len(g)] for i in range(2 * k + 1)]), axis=0)
    g = smooth(g, 16)
    x = x * to_samples(g, hop, len(x))
    # 慢速音量平整
    hop2 = int(0.25 * SR)
    r2 = smooth(frames_rms(x, hop2), 12)
    g2 = np.clip((np.median(r2) / r2) ** ride, 0.5, 2.0)
    return x * to_samples(g2, hop2, len(x))


def reverb(x, rng, rt60=2.4, pre=0.025, lp=2500.0):
    """合成殘響：指數衰減雜訊當 IR（越後面越暗），numpy FFT 摺積。輸出與輸入同均方根。"""
    n = int(3.0 * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-6.91 * t / rt60)
    ir = spectral(ir, hp=120, lp=lp, tilt=3)
    ir = np.concatenate([np.zeros(int(pre * SR)), ir])
    L = 1 << int(np.ceil(np.log2(len(x) + len(ir))))
    y = np.fft.irfft(np.fft.rfft(x, L) * np.fft.rfft(ir, L), L)[:len(x)]
    return y * (np.sqrt(np.mean(x ** 2)) / np.sqrt(np.mean(y ** 2)))


def process(x, p, rng):
    x = spectral(x, lp=p['lp'])
    x = tame(x, p['ratio'], p['ride'])
    wet = p['wet']
    x = np.sqrt(1 - wet) * x + np.sqrt(wet) * reverb(x, rng)
    x = tame(x, 3.0, 0.0)  # 殘響後再輕壓一次，確保沒有突出的近聲
    x = x[int(PRE * SR):int((PRE + CLIP) * SR)]
    x *= p['rms'] / np.sqrt(np.mean(x ** 2))
    return x


def write_wav(path, x, sr=SR, ch=1):
    pcm = np.clip(np.round(x * 32767), -32768, 32767).astype('<i2')
    import wave
    with wave.open(path, 'wb') as w:
        w.setnchannels(ch)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def make_loop(raw, n, m):
    """與 App 的 SynthBedSource.makeLoop 相同：尾端 m 個樣本等功率交叉淡化疊回開頭。"""
    out = raw[:n].copy()
    a = np.arange(m) / m * np.pi / 2
    out[:m] = raw[:m] * np.sin(a) + raw[n:n + m] * np.cos(a)
    return out


def preview(bed, seconds, path):
    """模擬 App：40 秒循環、左右聲道取同一循環的不同位移（去相關），播 1.5 圈以便聽接縫。"""
    n, m = int(40 * SR), int(3 * SR)
    loop = make_loop(bed, n, m)
    i = np.arange(int(seconds * SR))
    left, right = loop[i % n], loop[(i + int(0.37 * n)) % n]
    fade = np.minimum(1, np.minimum(i / (2 * SR), (len(i) - i) / (2 * SR)))
    st = np.stack([left * fade, right * fade], axis=1).reshape(-1)
    tmp = path + '.wav'
    write_wav(tmp, st, ch=2)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', tmp, '-ar', '22050', '-b:a', '128k', path], check=True)
    os.remove(tmp)


def stats(x):
    hop = int(0.005 * SR)
    r = frames_rms(x, hop)
    return f'rms {np.sqrt(np.mean(x**2)):.3f}  peak {np.max(np.abs(x)):.2f}  5ms峰/中位 {np.percentile(r, 99.5) / np.median(r):.1f}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--cache', default='build/soundscape-cache')
    ap.add_argument('--out', default='assets/audio/beds')
    ap.add_argument('--preview', default='')
    ap.add_argument('--only', default='')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    credits = []
    for i, (key, p) in enumerate(BEDS.items()):
        if a.only and key not in a.only.split(','):
            continue
        path, meta = fetch(p['title'], a.cache)
        x = decode(path)
        rng = np.random.default_rng(1000 + i)
        need = CLIP + PRE
        if p.get('shuffle'):
            x = shuffle_extend(x, need, rng)
        else:
            s = int(max(0, p['start'] - PRE) * SR)
            x = x[s:s + int(need * SR)]
            if len(x) < need * SR:
                raise SystemExit(f'{key}：從 {p["start"]} 秒起不足 {CLIP} 秒')
        y = process(x, p, rng)
        write_wav(os.path.join(a.out, f'{key}.wav'), y)
        print(f'{key:5s} {stats(y)}')
        if a.preview:
            os.makedirs(a.preview, exist_ok=True)
            preview(y, 60, os.path.join(a.preview, f'{key}.mp3'))
        credits.append(f'| {LABEL[key]} | `{key}.wav` | [{meta["title"]}]({meta["page"]}) | {meta["artist"] or "—"} | {meta["license"]} |')
    if not a.only:
        with open(os.path.join(os.path.dirname(a.out.rstrip('/')), 'CREDITS.md'), 'w') as f:
            f.write('# 音景錄音來源\n\n八經卦音景取自 Wikimedia Commons 上的 CC0 或公有領域錄音，經 `tools/soundscape/build_beds.py` '
                    '濾波、壓縮、加殘響後截取 56 秒。CC0／公有領域不要求標示，此處列出以示感謝。\n\n'
                    '| 卦 | 檔案 | 來源 | 作者 | 授權 |\n|---|---|---|---|---|\n' + '\n'.join(credits) + '\n')


if __name__ == '__main__':
    main()
