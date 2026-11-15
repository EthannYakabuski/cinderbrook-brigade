"""Assemble a compact review/site using only verified native runtime captures.

No screenshots are synthesized, recolored, stretched, resampled or composited.
The same standalone HTML works locally in review/ and as prepared public/ content.
This script never changes hosting settings or touches the public/play Web export.
"""
from pathlib import Path
import argparse
import html
import json
import shutil

from validate_store import validate_captures

ROOT = Path(__file__).resolve().parents[1]
PROVENANCE = ROOT / 'marketing/screenshots/provenance.json'
NATIVE_ACCEPTANCE = ROOT / 'docs/native-acceptance.json'
# Owner authorization and subsequent repository read-back established these
# settings. Configuration is distinct from a successful deployment.
HOSTING_CONFIGURATION = {
    'configured': True,
    'source': 'GitHub Actions',
    'PAGES_DEPLOY_ENABLED': True,
    'configuration_owner_authorized': True,
    'deployment_verified': False,
    'deployment_evidence': None,
}


def esc(value):
    return html.escape(str(value), quote=True)


def read_json(path, fallback):
    return json.loads(path.read_text(encoding='utf-8-sig')) if path.exists() else fallback


def prepare_context():
    listing = read_json(ROOT / 'marketing/store/store-listing.json', {})
    data = read_json(PROVENANCE, {'captures': [], 'sources': {}})
    # A review may describe unfinished work, so missing profiles remain PENDING.
    # This does not change validate_store.py's strict default or any CI gate.
    integrity = validate_captures(allow_pending=True)
    recorded = data.get('captures', [])
    for item in recorded:
        if item.get('capture_kind') not in ('android_emulator', 'physical_android'):
            raise ValueError('Review only accepts identified native Android runtime captures')
        if type(item.get('review_visible', True)) is not bool:
            raise ValueError('review_visible must be a boolean: ' + item['path'])
    # Curation is metadata-only: original pixels and source receipts are kept.
    # Removing an item from provenance also removes it from the next gallery.
    captures = [item for item in recorded if item.get('review_visible', True)]
    native = read_json(NATIVE_ACCEPTANCE, {})
    if native.get('full_acceptance_claimed') is True and native.get('status') not in ('PASS', 'COMPLETE'):
        raise ValueError('Native receipt contradicts its full-acceptance claim')
    observations = native.get('verified_observations', [])
    profiles = sorted({item['profile'] for item in captures})
    return {
        'listing': listing, 'captures': captures, 'recorded_count': len(recorded),
        'profiles': profiles, 'integrity': integrity, 'native': native,
        'observations': observations, 'play_exists': (ROOT / 'build/site/play/index.html').exists(),
        'initial_profile': 'phone' if 'phone' in profiles else (profiles[0] if profiles else 'phone'),
    }


def native_status(context):
    native = context['native']
    if not native:
        return '<p class="pending">Native acceptance has not been recorded yet. Images alone do not establish gameplay, ad-callback or persistence acceptance.</p>'
    complete = native.get('status') in ('PASS', 'COMPLETE') and native.get('full_acceptance_claimed') is True
    title = 'Recorded native acceptance complete' if complete else 'Native acceptance in progress'
    final_status = native.get('final_package_acceptance', 'See the recorded artifact scope and remaining checks.')
    observations = context['observations']
    observed = ''.join(f'<li><strong>{esc(item.get("result", "RECORDED"))}:</strong> {esc(item.get("summary", ""))}</li>' for item in observations)
    remaining = ''.join(f'<li>{esc(item)}</li>' for item in native.get('remaining_acceptance', []))
    detail = f'<ul>{observed}</ul>' if observed else '<p>No individual native results are recorded.</p>'
    if remaining:
        detail += f'<p><strong>Remaining or untested:</strong></p><ul>{remaining}</ul>'
    return (f'<div class="native-status"><strong>{esc(title)}</strong><p>{esc(final_status)}</p>'
            f'<details><summary>{len(observations)} recorded observations and testing limits</summary>{detail}'
            '<p><a href="__ROOT__docs/native-acceptance.json">Read the artifact-specific native receipt</a></p></details></div>')


def gallery_html(context):
    labels = {'phone': 'Phone', 'tablet7': '7-inch tablet layout', 'tablet10': '10-inch tablet layout'}
    gallery = []
    for item in context['captures']:
        profile = item['profile']
        origin = 'physical Android device' if item.get('physical_device') else 'Android emulator, logical display profile'
        caption = f"{labels.get(profile, profile)} · {origin} · {item['width']}×{item['height']}"
        gallery.append(f'<figure class="capture" data-profile="{esc(profile)}"><a href="__ROOT__{esc(item["path"])}" target="_blank" rel="noopener"><img loading="lazy" src="__ROOT__{esc(item["path"])}" alt="{esc(item["description"])}" width="{item["width"]}" height="{item["height"]}"></a><figcaption><strong>{esc(item["description"])}</strong><span>{esc(caption)}</span></figcaption></figure>')
    return ''.join(gallery) or '<p class="pending">No native runtime captures are selected for this gallery yet. Promotional artwork is not gameplay evidence.</p>'

TEMPLATE='''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cinderbrook Brigade · Prototype review</title><meta name="description" content="Sweep a blue water jet across six miniature neighborhoods in Cinderbrook Brigade, a one-finger firefighting arcade game for Android.">
<meta name="theme-color" content="#071b2c"><link rel="icon" href="assets/brand/app-icon-512.png">
<style>
:root{color-scheme:dark;--ink:#071b2c;--panel:#102a3a;--paper:#fff0d4;--muted:#adc2cc;--aqua:#72ddd9;--coral:#ff947e;--line:#2a4552}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:radial-gradient(ellipse at 80% 10%,#153945 0,transparent 50%),var(--ink);color:var(--paper);font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;line-height:1.6}a{color:var(--aqua)}button,a{touch-action:manipulation}button:focus-visible,a:focus-visible{outline:3px solid var(--aqua);outline-offset:5px}.wrap{width:min(1120px,calc(100% - 40px));margin:auto}header{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:28px 0}header a{display:flex;gap:12px;align-items:center;text-decoration:none;color:var(--paper);font-size:15px;font-weight:800;letter-spacing:.03em}header img{width:46px;height:46px;border-radius:12px}.tag{border:1px solid var(--line);border-radius:999px;padding:7px 13px;color:var(--muted);font-size:12px;font-weight:650;letter-spacing:.05em}.hero{display:grid;grid-template-columns:1fr;gap:24px;padding:20px 0 46px}.eyebrow{font-size:11px;letter-spacing:.15em;font-weight:800;color:var(--aqua);text-transform:uppercase}h1{font-size:clamp(36px,5.4vw,66px);line-height:1.04;letter-spacing:-.05em;max-width:820px;margin:15px 0 20px}h2{font-size:clamp(28px,3.6vw,42px);line-height:1.1;letter-spacing:-.035em;margin:10px 0 16px}h3{font-size:22px;line-height:1.2;letter-spacing:-.025em;margin:14px 0 12px}p{margin:0 0 18px}.lede{font-size:clamp(17px,2vw,21px);color:var(--muted);max-width:730px}.hero-art{margin:8px 0 0}.hero-art img{display:block;width:100%;height:auto;border-radius:22px;border:1px solid #385966;box-shadow:0 22px 70px #0005}figcaption{font-size:12px;color:var(--muted);margin-top:10px}.actions{display:flex;flex-wrap:wrap;gap:12px;margin:24px 0 2px}.button{display:inline-flex;align-items:center;justify-content:center;min-height:48px;padding:11px 20px;border-radius:12px;border:1px solid var(--line);color:var(--paper);text-decoration:none;font-size:14px;font-weight:750}.button.primary{background:var(--aqua);border-color:var(--aqua);color:var(--ink)}.button.disabled{opacity:.6;cursor:default}.facts{display:flex;flex-wrap:wrap;gap:8px;margin:8px 0 0}.facts span{font-size:12px;color:var(--muted);padding:7px 13px;border-radius:999px;border:1px solid var(--line)}section{padding:44px 0;border-top:1px solid var(--line)}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.card{background:linear-gradient(145deg,#193747,#102635);border:1px solid var(--line);border-radius:18px;padding:25px}.card p{font-size:15px;color:var(--muted);margin:0}.loop{display:grid;grid-template-columns:.65fr 1fr;gap:52px;align-items:center}.splash{margin:0;max-width:340px}.splash img{display:block;width:100%;height:auto;border-radius:18px;box-shadow:0 25px 50px #0005}.steps{padding:0;list-style:none;counter-reset:step}.steps li{counter-increment:step;position:relative;padding:0 0 20px 48px;color:var(--muted)}.steps li:before{content:counter(step);position:absolute;left:0;top:1px;background:#184d56;border:1px solid #38757b;border-radius:50%;width:29px;height:29px;text-align:center;font-size:14px;color:var(--aqua);font-weight:750}.steps strong{display:block;color:var(--paper);margin-bottom:3px}.quote{border-left:3px solid var(--coral);padding:0 0 0 20px;color:var(--muted);font-style:italic}.sectionhead{display:flex;gap:24px;align-items:end;justify-content:space-between;margin-bottom:24px}.sectionhead p{color:var(--muted);max-width:520px;font-size:14px;margin:0}.tabs{display:flex;flex-wrap:wrap;gap:10px;margin:20px 0}.tabs button{border:1px solid var(--line);background:#102a3a;color:var(--paper);padding:11px 16px;border-radius:10px;font:700 13px inherit;cursor:pointer}.tabs button[aria-pressed=true]{background:var(--aqua);color:var(--ink);border-color:var(--aqua)}.gallery{display:grid;grid-template-columns:repeat(3,1fr);gap:22px}.capture{margin:0}.capture a{display:block;border:1px solid var(--line);border-radius:15px;background:#04121d;overflow:hidden}.capture img{width:100%;height:auto;display:block}.capture strong,.capture span{display:block}.capture strong{color:var(--paper);font-weight:650;font-size:13px}.capture span{font-size:11px;margin-top:4px}.capture[hidden]{display:none}.pending{padding:24px;border:1px dashed var(--line);border-radius:14px;color:var(--muted);grid-column:1/-1}.details{display:grid;grid-template-columns:1fr 1fr;gap:28px}.details article{padding:26px;border:1px solid var(--line);border-radius:18px}.details p{color:var(--muted);font-size:14px}.details ul{padding-left:20px;color:var(--muted);font-size:14px}.details li{margin:7px 0}.badge-strip{display:flex;gap:18px;flex-wrap:wrap;align-items:center}.badge-strip img{width:84px;height:84px;border-radius:15px}.quiet{font-size:13px;color:var(--muted)}footer{padding:34px 0 48px;border-top:1px solid var(--line);font-size:12px;color:var(--muted);display:flex;justify-content:space-between;gap:20px;flex-wrap:wrap}footer a{margin-left:16px}details{margin-top:16px}summary{cursor:pointer;font-size:13px;font-weight:700;color:var(--aqua)}details p{margin-top:12px}code{color:#c7eeee;font-size:12px}.native-status{padding:20px 24px;border:1px solid var(--line);border-radius:15px;background:#102a3a;margin:20px 0}.native-status>strong{color:var(--aqua)}.native-status p,.native-status li{font-size:13px;color:var(--muted)}.native-status p{margin:8px 0 0}.native-status ul{padding-left:20px}.sr-only{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0,0,0,0)}
@media(max-width:700px){.wrap{width:min(100% - 28px,1120px)}header{padding:20px 0}.tag{display:none}.hero{padding-top:6px}.grid{grid-template-columns:1fr}.loop{grid-template-columns:1fr;gap:30px}.splash{max-width:280px;margin:auto}.sectionhead{display:block}.gallery{grid-template-columns:repeat(2,1fr);gap:14px}.details{grid-template-columns:1fr}.card{padding:22px}section{padding:32px 0}.capture strong{font-size:11px}.capture span{font-size:10px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
</style></head><body><div class="wrap"><header><a href="#"><img src="assets/brand/app-icon-512.png" alt="">CINDERBROOK BRIGADE</a><span class="tag">ANDROID PROTOTYPE · 14 NOV 2026</span></header>
<main><div class="hero"><div><span class="eyebrow">A one-finger firefighting arcade game</span><h1>A little truck.<br>A town worth saving.</h1><p class="lede">Sweep a cool blue water jet across a tiny burning world. Watch the flames turn to steam, lift to refill, and bring the neighborhood back to calm.</p><div class="actions">__PLAY_LINK__<a class="button" href="https://github.com/EthannYakabuski/cinderbrook-brigade">Project &amp; build instructions ↗</a><a class="button" href="#runtime">Runtime evidence status</a></div><div class="facts"><span>36 authored incidents</span><span>6 neighborhoods</span><span>Portrait touch controls</span><span>Local offline progress</span></div></div><figure class="hero-art"><img src="assets/brand/feature-graphic-1024x500.png" width="1024" height="500" alt="Cinderbrook Brigade title beside a coral fire engine cooling a cottage roof in a golden riverside village."><figcaption>Original illustrated key art. Runtime evidence status appears below.</figcaption></figure></div>
<section aria-label="Three reasons to play"><div class="grid">__CARDS__</div></section>
<section class="loop"><figure class="splash"><img src="assets/brand/splash-1080x1920.png" width="1080" height="1920" loading="lazy" alt="Coral fire engine spraying a cottage beside a teal creek beneath the Cinderbrook Brigade title."><figcaption>Portrait splash artwork, generated for this game.</figcaption></figure><div><span class="eyebrow">The whole idea fits in your hand</span><h2>Aim. Cool. Breathe.</h2><ol class="steps"><li><strong>Drag to sweep the water.</strong>Cover a generous area and cool the hottest roofs before fire spreads.</li><li><strong>Lift to refill.</strong>Choose your moment, rebuild the reserve and read the next ember warning.</li><li><strong>Save the incident. Grow the brigade.</strong>Earn stars, supply coins and XP. Upgrade your equipment and return for a cleaner rescue.</li></ol><p class="quote">When the old station bell rings, everyone in Cinderbrook leaves a light on. Your little truck follows those lights, one neighborhood at a time.</p></div></section>
<section id="runtime"><div class="sectionhead"><div><span class="eyebrow">Native runtime acceptance</span><h2>Life on the water line.</h2></div><p>This gallery requires unaltered native Android runtime captures with recorded dimensions and a file hash. The capture count below reports what is actually available. Emulator evidence, when present, does not establish physical-device performance.</p></div>__NATIVE_STATUS__<div class="tabs" role="group" aria-label="Runtime screenshot device profile"><button data-filter="phone" aria-pressed="true">Phone</button><button data-filter="tablet7" aria-pressed="false">7-inch tablet</button><button data-filter="tablet10" aria-pressed="false">10-inch tablet</button></div><div class="gallery">__GALLERY__</div><p class="quiet" style="margin-top:20px">__CAPTURE_NOTE__ Select a capture to inspect its original pixels.</p></section>
<section><div class="details"><article><span class="eyebrow">A fair rhythm</span><h3>One more good rescue.</h3><p>Daily Incidents, seven-day login gifts and Endless Watch give the little town a fresh reason to call. Five upgrade branches improve cooling, capacity, sweep width, refill rate and wet protection. Twenty illustrated achievements celebrate progress.</p><div class="badge-strip"><img src="assets/brand/first_response.png" alt="First Response achievement badge"><img src="assets/brand/three_star.png" alt="A Clean Sweep achievement badge"><img src="assets/brand/brigade_rank_10.png" alt="Brigade Chief achievement badge"></div></article><article><span class="eyebrow">Monetization &amp; prototype status</span><h3>At the natural breaks.</h3><ul><li>Reserved banner space on the menu and results.</li><li>An interstitial opportunity at Next/Retry after every third durably completed round.</li><li>One optional emergency continue per incident, granted only by an earned-ad callback and resumed by the player.</li><li>Ordinary retries and local progression remain available if ads are unavailable.</li></ul><p>This build uses Google test IDs. Production Play Games IDs are blank and disabled. Web play has local progress without native ads or pretend ad rewards.</p></article></div><details><summary>Technical notes and remaining release setup</summary><p class="quiet">Godot 4.5.1, Compatibility renderer, Kenney 3D assets and UI, original generated branding, seven original instrumental loops, separate music/effects and reduced-motion controls. The owner still needs production account/ID setup, backend verification, release signing review, final audience and Data safety declarations, a hosted privacy policy and physical-device testing. __HOSTING_NOTE__</p></details></section></main>
<footer><span>Cinderbrook Brigade · Original project work Apache-2.0 · Kenney assets CC0</span><span><a href="support.html">Prototype support</a><a href="privacy-draft.html">Privacy draft</a></span></footer></div>
<script>const tabs=[...document.querySelectorAll('[data-filter]')],shots=[...document.querySelectorAll('.capture')];function choose(profile){tabs.forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.filter===profile)));shots.forEach(s=>s.hidden=s.dataset.profile!==profile)}tabs.forEach(b=>b.addEventListener('click',()=>choose(b.dataset.filter)));choose('__INITIAL_PROFILE__');</script></body></html>'''

def render(context, destination):
    if destination not in ('review', 'public'):
        raise ValueError('Unknown review destination')
    captures = context['captures']
    cards = ''.join(f'<article class="card"><span class="eyebrow">0{i+1}</span><h3>{esc(card["title"])}</h3><p>{esc(card["copy"])}</p></article>' for i, card in enumerate(context['listing']['three_selling_cards']))
    play = 'play/index.html' if destination == 'public' else '../play/index.html'
    playlink = (f'<a class="button primary" data-web-link href="{play}">Play the Web prototype &#8594;</a>' if context['play_exists']
                else '<span class="button disabled">Web export pending verification</span>')
    if captures:
        note = f'{len(captures)} selected native runtime images across {len(context["profiles"])} device profiles; {context["recorded_count"]} native capture records verified.'
    else:
        note = f'No gallery images selected; {context["recorded_count"]} native capture records available.'
    missing = context['integrity'].get('missing_android_profiles', [])
    if missing:
        note += ' Capture profiles still pending: ' + ', '.join(missing) + '.'
    hosting_note = ('The owner-approved Pages configuration uses GitHub Actions with PAGES_DEPLOY_ENABLED enabled. '
                    'This review contains no verified deployment receipt. The Pages workflow requires successful '
                    'validation and Android CI for its exact source revision; local assembly is not deployment.')
    output = (TEMPLATE.replace('__CARDS__', cards).replace('__GALLERY__', gallery_html(context))
              .replace('__PLAY_LINK__', playlink).replace('__CAPTURE_NOTE__', esc(note))
              .replace('__NATIVE_STATUS__', native_status(context)).replace('__HOSTING_NOTE__', hosting_note)
              .replace('__INITIAL_PROFILE__', context['initial_profile']))
    # assemble_site owns the marketing tree. Link to the original capture bytes.
    output = output.replace('assets/brand/', '__ROOT__marketing/')
    for badge in ('first_response', 'three_star', 'brigade_rank_10'):
        output = output.replace('__ROOT__marketing/' + badge + '.png', '__ROOT__marketing/achievements/' + badge + '.png')
    output = output.replace('__ROOT__', '../' if destination == 'review' else '')
    output = output.replace('</script>', "if(location.protocol==='file:'){document.querySelectorAll('[data-web-link]').forEach(a=>{const label=document.createElement('span');label.className='button disabled';label.textContent='Web play needs HTTP';a.replaceWith(label);});const note=document.createElement('p');note.className='quiet';note.style.marginTop='14px';note.textContent='To play locally, serve the assembled build/site folder over HTTP. For example: python -m http.server 8765 --bind 127.0.0.1 --directory build/site, then open http://127.0.0.1:8765/play/. Opening a file from disk cannot reliably load the Godot Web export.';document.querySelector('.actions').after(note);}</script>")
    if '__ROOT__' in output or any(marker in output for marker in ('__CARDS__', '__GALLERY__', '__NATIVE_STATUS__', '__HOSTING_NOTE__', '__INITIAL_PROFILE__')):
        raise ValueError('Unresolved review template marker')
    manifest = {
        'captures': len(captures), 'recorded_native_captures': context['recorded_count'],
        'profiles': context['profiles'], 'capture_provenance': 'marketing/screenshots/provenance.json',
        'gallery_paths': [item['path'] for item in captures],
        'capture_integrity_status': context['integrity']['status'],
        'art_type': 'Original generated marketing illustration', 'screenshots_modified': False,
        'web_export_present': context['play_exists'],
        'native_acceptance_receipt': 'docs/native-acceptance.json' if context['native'] else None,
        'native_acceptance_status': context['native'].get('status', 'NOT_RECORDED'),
        'native_full_acceptance_claimed': context['native'].get('full_acceptance_claimed') is True,
        'native_final_package_acceptance': context['native'].get('final_package_acceptance'),
        'hosting': dict(HOSTING_CONFIGURATION), 'hosting_settings_changed_by_assembler': False,
    }
    return output, manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Validate inputs and render in memory; do not write HTML or manifests')
    args = parser.parse_args()
    context = prepare_context()
    rendered = {destination: render(context, destination) for destination in ('review', 'public')}
    if args.check:
        print(json.dumps({'mode': 'read-only review validation', **rendered['review'][1]}, indent=2))
        return
    for destination, (output, manifest) in rendered.items():
        out = ROOT / destination
        out.mkdir(parents=True, exist_ok=True)
        for name in ('support.html', 'privacy-draft.html'):
            shutil.copy2(ROOT / 'marketing/store' / name, out / name)
        (out / 'index.html').write_text(output, encoding='utf-8', newline='\n')
        (out / 'review-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(f'Review prepared in review/ and public/ with {len(context["captures"])} selected verified native captures; public/play preserved.')


if __name__ == '__main__':
    main()
