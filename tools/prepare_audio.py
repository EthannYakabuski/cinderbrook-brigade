"""Cinderbrook Brigade's original, deterministic seven-cue score and water Foley.

Requires NumPy (available in the installed Blender Python). No downloads or samples.
Source Kenney OGGs are copied byte-for-byte with their CC0 notices. All generated
tones/noise, melodies, bass lines and arrangements below are original project work.
"""
from pathlib import Path
import hashlib,json,math,shutil,wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio'
KENNEY=ROOT.parents[1]/'AllOfKennysAssets'
SR=32000
# Sixteen-bar cues with an eight-chord arc, A/B melody, bass, chord pulses and
# a neighborhood-specific countermelody. None is a transposition of another.
SCORES={
'menu':dict(title='A Light in the Station',bpm=84,key=50,kind='wood',beat=.42,pad=.85,
 chords=[[0,4,7,11],[9,12,16,19],[5,9,12,16],[7,11,14,17],[0,4,7,14],[4,7,11,14],[5,9,12,16],[7,11,14,19]],
 a=[24,None,28,31,28,None,26,24,21,None,24,28,26,None,19,None],
 b=[29,28,None,24,26,24,21,None,19,21,24,None,26,28,24,None]),
'district_01':dict(title='Maple Mews Morning',bpm=108,key=48,kind='wood',beat=.62,pad=.55,
 chords=[[0,4,7,12],[5,9,12,16],[9,12,16,19],[7,11,14,17],[0,4,7,11],[2,5,9,12],[5,9,12,16],[7,11,14,19]],
 a=[24,28,31,None,28,26,24,None,21,24,28,31,29,28,26,None],
 b=[31,28,24,28,26,None,24,21,24,26,28,None,26,19,24,None]),
'district_02':dict(title='Pines and Camp Lanterns',bpm=94,key=55,kind='pluck',beat=.45,pad=.75,
 chords=[[0,4,7,14],[5,9,12,16],[0,7,11,14],[7,11,14,19],[9,12,16,19],[5,9,12,16],[2,5,9,12],[7,11,14,17]],
 a=[24,None,19,21,24,26,None,28,26,None,24,21,19,None,16,19],
 b=[28,31,None,28,26,24,21,None,24,19,21,24,26,None,24,None]),
'district_03':dict(title='Copperworks Shuffle',bpm=116,key=45,kind='bell',beat=.90,pad=.35,
 chords=[[0,3,7,10],[5,8,12,15],[0,3,7,14],[7,10,14,17],[8,12,15,19],[3,7,10,14],[5,8,12,15],[7,11,14,17]],
 a=[24,None,27,31,34,31,27,None,29,27,24,None,22,24,27,None],
 b=[31,34,31,None,29,27,24,22,24,None,27,29,31,27,24,None]),
'district_04':dict(title='Apple Blossom Relay',bpm=102,key=53,kind='pluck',beat=.58,pad=.62,
 chords=[[0,4,7,14],[9,12,16,19],[2,5,9,12],[7,11,14,17],[5,9,12,16],[0,4,7,11],[2,5,9,14],[7,11,14,19]],
 a=[24,26,28,31,28,None,24,21,26,29,28,26,24,None,19,21],
 b=[29,None,28,26,24,21,19,None,21,24,26,28,31,28,24,None]),
'district_05':dict(title='Little Lights by the Lake',bpm=112,key=50,kind='bell',beat=.70,pad=.55,
 chords=[[0,4,7,11],[4,7,11,14],[5,9,12,16],[7,11,14,17],[9,12,16,19],[2,5,9,12],[5,9,12,16],[7,11,14,19]],
 a=[31,28,24,None,26,29,28,None,24,28,31,33,31,None,28,26],
 b=[33,31,28,24,26,None,29,28,26,24,21,None,19,21,24,None]),
'district_06':dict(title='The Last Lantern Home',bpm=98,key=52,kind='wood',beat=.68,pad=.85,
 chords=[[0,3,7,10],[8,12,15,19],[3,7,10,14],[7,11,14,17],[0,3,7,14],[5,8,12,15],[8,12,15,19],[7,11,14,17]],
 a=[24,27,31,None,29,27,24,None,22,24,27,31,34,None,31,29],
 b=[36,None,34,31,29,27,24,22,24,27,29,None,31,27,24,None])}

def hz(n):return 440*2**((n-69)/12)
def metrics(x):
    return dict(seconds=round(len(x)/SR,4),sample_rate=SR,channels=2,
        peak_dbfs=round(20*math.log10(max(1e-12,float(np.abs(x).max()))),2),
        rms_dbfs=round(20*math.log10(max(1e-12,float(np.sqrt(np.mean(x*x))))),2),
        clipped_samples=int(np.count_nonzero(np.abs(x)>=.999)),
        dc_offset=round(float(np.mean(x)),8),
        boundary_delta=round(float(np.abs(x[0]-x[-1]).max()),7))
def write(name,x,folder='music',loop=False):
    path=OUT/folder/(name+'.wav');path.parent.mkdir(parents=True,exist_ok=True)
    pcm=(np.clip(x,-.99,.99)*32767).astype('<i2')
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(pcm.tobytes())
    record=dict(path='res://'+str(path.relative_to(ROOT)).replace('\\','/'),loop=loop,
                sha256=hashlib.sha256(path.read_bytes()).hexdigest(),**metrics(x))
    return record

def compose(spec,seed):
    rng=np.random.default_rng(seed);beat=60/spec['bpm'];frames=round(64*beat*SR)
    mix=np.zeros((frames,2),dtype=np.float64)
    def add(note,start,length,amp,pan=0,kind='wood'):
        n=round(length*SR);t=np.arange(n)/SR;f=hz(note)
        if kind=='pad':
            env=np.clip(t/.24,0,1)*np.clip((length-t)/.55,0,1)
            v=(np.sin(2*np.pi*f*t)+.18*np.sin(2*np.pi*f*2*t+.3))*.75*env
        elif kind=='bass':
            env=(1-np.exp(-t*100))*np.exp(-t/(length*.6))*np.clip((length-t)/.045,0,1)
            v=(np.sin(2*np.pi*f*t)+.25*np.sin(4*np.pi*f*t))*.8*env
        elif kind=='pluck':
            env=(1-np.exp(-t*350))*np.exp(-t*3.8)*np.clip((length-t)/.045,0,1)
            v=(np.sin(2*np.pi*f*t)+.3*np.sin(2*np.pi*f*2*t)*np.exp(-t*6)+.13*np.sin(2*np.pi*f*3*t))*env
        elif kind=='bell':
            env=(1-np.exp(-t*500))*np.exp(-t*3.0)*np.clip((length-t)/.045,0,1)
            v=(np.sin(2*np.pi*f*t)+.22*np.sin(2*np.pi*f*2.01*t)*np.exp(-t*4)+.07*np.sin(2*np.pi*f*4.03*t))*env
        else:
            env=(1-np.exp(-t*300))*np.exp(-t*5.0)*np.clip((length-t)/.04,0,1)
            v=(np.sin(2*np.pi*f*t)+.27*np.sin(2*np.pi*f*3.99*t)*np.exp(-t*14))*.9*env
        inds=(round(start*SR)+np.arange(n))%frames
        np.add.at(mix[:,0],inds,v*amp*math.sqrt((1-pan)/2))
        np.add.at(mix[:,1],inds,v*amp*math.sqrt((1+pan)/2))
    def drum(start,kind,amp):
        length=.16 if kind=='hat' else .30;n=round(length*SR);t=np.arange(n)/SR
        if kind=='kick': v=np.sin(2*np.pi*(48*t+2.6*(1-np.exp(-t*25))))*np.exp(-t*20)
        else:
            noise=rng.uniform(-1,1,n);noise-=np.convolve(noise,np.ones(15)/15,mode='same')
            v=noise*np.exp(-t*(65 if kind=='hat' else 25))
            if kind=='rim':v+=.45*np.sin(2*np.pi*740*t)*np.exp(-t*75)
        v*=np.clip(t/.003,0,1)*np.clip((length-t)/.02,0,1)
        inds=(round(start*SR)+np.arange(n))%frames
        for ch in range(2):np.add.at(mix[:,ch],inds,v*amp)
    for bar in range(16):
        chord=spec['chords'][bar%8];s=bar*4*beat
        for i,n in enumerate(chord):
            add(spec['key']+n,s-.12,4*beat+.6,.042*spec['pad'],(i-1.5)*.36,'pad')
        # Carefully voiced upbeat chord comping and a changing root/fifth bass.
        for b in [0,1.5,2.5,3.5]:
            for i,n in enumerate(chord[:3]):add(spec['key']+n+12,s+b*beat,.46,.030,(-.24 if b<2 else .24),'pluck')
        bass=[chord[0]-12,chord[0]-12,chord[0]-5,chord[0]-12]
        for b,n in enumerate(bass):add(spec['key']+n,s+b*beat,.8*beat,.13,0,'bass')
        melody=spec['a'] if (bar//4)%2==0 else spec['b']
        for k in range(4):
            index=((bar%4)*4+k)%16;note=melody[index]
            if note is not None:add(spec['key']+note,s+(k+.04)*beat,1.2,.115,math.sin(bar*.7)*.25,spec['kind'])
        # B section answers the melody in a quieter upper register.
        if bar>=8:
            for k in [1,3]:add(spec['key']+chord[(bar+k)%4]+24,s+(k+.5)*beat,.9,.032,-.48,'bell')
        for b in [0,2]:drum(s+b*beat,'kick',.11*spec['beat'])
        for b in [1,3]:drum(s+b*beat,'rim',.045*spec['beat'])
        for b in range(8):drum(s+b*.5*beat,'hat',.023*spec['beat']*(.7 if b%2 else 1))
    # Very light musical delay wraps with the loop; DC is removed before limiting.
    original=mix.copy()
    mix+=np.roll(original,round(.75*beat*SR),axis=0)[:,::-1]*.12
    mix+=np.roll(original,round(1.5*beat*SR),axis=0)*.055
    mix-=mix.mean(axis=0)
    mix=np.tanh(mix*1.3)
    mix*=.50/max(.001,float(np.abs(mix).max()))
    return mix

tracks=[];manifest=dict(music={},sfx={},defaults=dict(music_db=-12,sfx_db=-6),tracks=tracks)
for index,(key,spec) in enumerate(SCORES.items()):
    record=write(key,compose(spec,1400+index),loop=True)
    record.update(id=key,title=spec['title'],bpm=spec['bpm'],bars=16,license='Apache-2.0 original project composition')
    tracks.append(record);manifest['music'][key]=record['path']

# Water sound uses bounded filtered noise and rounded onset/release; no sudden
# loud sirens or painful high-frequency spikes. Each loop is made periodic.
rng=np.random.default_rng(20261114)
def water(seconds,tail=False):
    n=round(seconds*SR);noise=rng.normal(0,.16,(n,2))
    sm=np.stack([np.convolve(noise[:,ch],np.ones(9)/9,mode='same') for ch in range(2)],axis=1)
    low=np.stack([np.convolve(noise[:,ch],np.ones(110)/110,mode='same') for ch in range(2)],axis=1)
    t=np.arange(n)/SR;mod=(.72+.15*np.sin(2*np.pi*3*t)+.08*np.sin(2*np.pi*7*t))[:,None]
    x=(sm*.7+low*1.3)*mod
    if tail:x*=np.exp(-t*2.6)[:,None]*np.clip(t/.015,0,1)[:,None]*np.clip((seconds-t)/.07,0,1)[:,None]
    else:
        fade=round(.06*SR);start=x[:fade].copy();end=x[-fade:].copy();blend=np.linspace(0,1,fade)[:,None]
        x[:fade]=start*blend+end*(1-blend);x[-fade:]=x[:fade]
        # Set exact endpoints so transport wrap never contains a discontinuity.
        x[-1]=x[0]
    return x
for key,seconds,tail in [('water',2.0,False),('splash',.5,True),('extinguish',.9,True)]:
    x=water(seconds,tail);x*=.24/max(.001,float(np.abs(x).max()))
    record=write(key,x,'sfx',not tail);tracks.append(dict(id=key,license='Apache-2.0 original synthesized Foley',**record));manifest['sfx'][key]=record['path']

def jingle(notes,seconds):
    n=round(seconds*SR);x=np.zeros((n,2));step=(seconds-.35)/len(notes)
    for i,note in enumerate(notes):
        start=round(i*step*SR);count=n-start;t=np.arange(count)/SR
        env=(1-np.exp(-t*150))*np.exp(-t*4.5)*np.clip((seconds-i*step-t)/.05,0,1)
        v=(np.sin(2*np.pi*hz(note)*t)+.18*np.sin(4*np.pi*hz(note)*t))*env*.17
        x[start:,0]+=v*.85;x[start:,1]+=v*.85
    return x
for key,notes,dur in [('win',[62,66,69,74],1.45),('lose',[62,60,57],1.25),('refill',[50,57,62],.75),('upgrade',[62,69,74,78],1.05)]:
    record=write(key,jingle(notes,dur),'sfx');tracks.append(dict(id=key,license='Apache-2.0 original composed cue',**record));manifest['sfx'][key]=record['path']

for key,pack,name in [('tap','kenney_interface-sounds','click_001.ogg'),('confirm','kenney_interface-sounds','confirmation_001.ogg'),('back','kenney_interface-sounds','back_001.ogg'),('error','kenney_interface-sounds','error_001.ogg'),('coins','kenney_rpg-audio','handleCoins2.ogg')]:
    src=KENNEY/pack/'Audio'/name;dst=OUT/'sfx'/(key+'.ogg');shutil.copy2(src,dst)
    license_dir=OUT/'LICENSES';license_dir.mkdir(parents=True,exist_ok=True)
    shutil.copy2(KENNEY/pack/'License.txt',license_dir/(pack+'-CC0.txt'))
    path='res://'+str(dst.relative_to(ROOT)).replace('\\','/')
    manifest['sfx'][key]=path
    tracks.append(dict(id=key,path=path,source=str(src.relative_to(KENNEY)).replace('\\','/'),license='Kenney CC0',sha256=hashlib.sha256(dst.read_bytes()).hexdigest(),loop=False))
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
report=dict(music_count=7,sfx_count=len(manifest['sfx']),no_clipping=all(r.get('clipped_samples',0)==0 for r in tracks),
            generated_signal_validation=[r for r in tracks if 'peak_dbfs' in r],
            listening_status='Original score rendered and signal-validated. Native app audio playback to be checked during runtime QA; no human listening review claimed.')
(OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='generated_signal_validation'}))
