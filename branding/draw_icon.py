from PIL import Image, ImageDraw
INK=(0x1C,0x1B,0x22); CARD=(0x26,0x24,0x2E); EARTH=(0xC9,0xA4,0x5C); RICE=(0xE0,0xC0,0x78); MT=(0x7E,0x6A,0x52)
# 謙 ䷎ bottom->top: 初六,六二,九三,六四,六五,上六
LINES=[False,False,True,False,False,False]
def fg(S, frame=True):
    """foreground on transparent S x S, content within central ~66%"""
    im=Image.new('RGBA',(S,S),(0,0,0,0)); d=ImageDraw.Draw(im)
    cx,cy=S/2,S/2
    # 0.1.0+13：0.60→0.52。自適應圖示可見範圍約為畫布 66.7%，0.60 時卦卡佔滿可見高度約 89%，
    # 桌面上顯得擁擠；0.52 時約 78%，與 icon-1024.png（使用者偏好的樣子）比例相同。
    ch=S*0.52; cw=ch*0.66
    if frame:
        d.rounded_rectangle((cx-cw/2,cy-ch/2,cx+cw/2,cy+ch/2),radius=S*0.03,fill=CARD,outline=EARTH,width=max(2,int(S*0.012)))
        m=S*0.03
        d.rectangle((cx-cw/2+m,cy-ch/2+m,cx+cw/2-m,cy+ch/2-m),outline=MT,width=max(1,int(S*0.006)))
    bw=cw*0.62; bh=ch*0.062; gap=ch*0.115
    top=cy-(5*gap)/2
    for i in range(6):
        yang=LINES[5-i]  # draw from top: 上六 first
        y=top+i*gap-bh/2
        col=RICE if yang else EARTH
        if yang: d.rectangle((cx-bw/2,y,cx+bw/2,y+bh),fill=col)
        else:
            seg=bw*0.42
            d.rectangle((cx-bw/2,y,cx-bw/2+seg,y+bh),fill=col); d.rectangle((cx+bw/2-seg,y,cx+bw/2,y+bh),fill=col)
    return im
def legacy(S):
    im=Image.new('RGBA',(S,S),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.rounded_rectangle((0,0,S-1,S-1),radius=S*0.22,fill=INK)
    f=fg(S*2).resize((S,S),Image.LANCZOS)
    # enlarge content for legacy (no safe-zone shrink): scale fg by 1.3
    big=fg(int(S*1.5*2)).resize((int(S*1.5),int(S*1.5)),Image.LANCZOS)  # 1.3×0.60/0.52 ≈ 1.5，傳統圖示外觀不變
    o=(S-big.size[0])//2; im.alpha_composite(big,(o,o)); return im
legacy(1024).save('master_legacy.png')
# adaptive foreground: 108dp canvas, safe 66dp -> our content 60% of canvas fits
fg(1024).save('master_fg.png')
# 各密度自適應前景（108dp 畫布）
for d,px in [('mdpi',108),('hdpi',162),('xhdpi',216),('xxhdpi',324),('xxxhdpi',432)]:
    fg(px*4).resize((px,px),Image.LANCZOS).save(f'android/res/mipmap-{d}/ic_launcher_foreground.png')
prev=Image.new('RGB',(1024+20+192+20+96+20+48,1024),(240,240,240))
prev.paste(legacy(1024),(0,0),legacy(1024))
x=1044
for s in (192,96,48):
    l=legacy(s); prev.paste(l,(x,0),l); x+=s+20
prev.save('preview.png')
