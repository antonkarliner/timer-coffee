import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'recipe_corpus_sample.dart';

const corpusRepository = '/Users/antonkarliner/GitHub/timer-coffee';

/// Resolve the parent even for a new file; refuse repository paths and symlinks.
File labelingPageOutput(String path) {
  const message = 'Labelling page output must be outside the repository.';
  final file = File(path).absolute;
  final parent = file.parent.resolveSymbolicLinksSync();
  final resolved =
      FileSystemEntity.typeSync(file.path, followLinks: false) !=
          FileSystemEntityType.notFound
      ? file.resolveSymbolicLinksSync()
      : '$parent/${file.uri.pathSegments.last}';
  final repository = Directory(corpusRepository).resolveSymbolicLinksSync();
  if (resolved == repository || resolved.startsWith('$repository/')) {
    throw const FileSystemException(message);
  }
  return File(resolved);
}

String buildLabelingPage(
  LabelingSample sample,
  List<Map<String, dynamic>> rows,
) {
  final byId = {for (final row in rows) row['id']: row};
  final data = [
    for (final item in sample.items)
      (() {
        final row = byId[item.diagnosticsId]!;
        final src = (row['src'] as List).cast<String>();
        return {
          'diagnostics_id': item.diagnosticsId,
          'step_index': item.stepIndex,
          'char_start': item.originalStart,
          'char_end': item.originalEnd,
          'outcome': item.outcome,
          'strata': item.strata,
          'text': src[item.stepIndex],
          'context': [
            for (var i = 0; i < src.length; i++)
              if (i != item.stepIndex) src[i],
          ],
          'coffee': row['coffee'],
          'water': row['water'],
          if (item.strata.contains('ai_more'))
            'ai': RecipeExpressionService.renderDescription(
              (row['cor'] as List)[item.stepIndex] as String,
              coffeeAmount: (row['coffee'] as num).toDouble(),
              waterAmount: (row['water'] as num).toDouble(),
            ),
        };
      })(),
  ];
  // Escape all angle brackets and slashes, including URLs present in user text.
  final encoded = jsonEncode(data)
      .replaceAll('<', r'\u003c')
      .replaceAll('>', r'\u003e')
      .replaceAll('/', r'\u002f');
  var hash = 2166136261;
  for (final code in sample.items.map((i) => i.identity).join('|').codeUnits) {
    hash = ((hash ^ code) * 16777619) & 0xffffffff;
  }
  return '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Recipe amount labelling</title>
<style>body{font:16px system-ui;background:#f6f7f9;color:#17202b;margin:32px auto;padding:0 24px;max-width:1000px}section{background:white;padding:24px;border-radius:12px;margin:16px 0}#step{white-space:pre-wrap;font-size:23px;line-height:1.6}mark{background:#ffe28a}button{margin:5px;padding:8px 12px;cursor:pointer}.active{background:#ffd571}li{white-space:pre-wrap}#chips button{border-radius:20px}small{color:#536071}</style>
<h1>Recipe amount labelling</h1><p id="progress"></p><small id="strata"></small>
<section><p id="amounts"></p><div id="step"></div><div id="choices"></div><div id="chips"></div><p id="hint"></p><button id="back">Back</button><button id="confirm">Confirm / Enter</button><button id="skip">Skip / s</button><button id="nothing">Nothing missed / n</button></section>
<section><h2>Recipe context</h2><ol id="context"></ol><h3 id="aiTitle"></h3><p id="ai"></p></section>
<section><h2>Labels</h2><p>1 Coffee: scales with coffee dose. “Add 15 g coffee”.</p><p>2 Water: incremental water. “Pour another 60 g water”.</p><p>3 Fixed: keep the amount unchanged. “Use a 500 ml kettle”.</p><p>4 Cumulative target water: water total reached so far. “Pour to 250 g”.</p><p>5 Not an amount: an unrelated match. “Use model 60g”.</p><p>Enter confirms, Backspace goes back, s skips. For find-missed steps select text, then press 1–5; repeat as needed. n confirms nothing missed.</p><button id="export">Export labels</button><p id="status"></p></section>
<script>
'use strict';
const items=$encoded;
const storageKey='recipe-corpus-labels-$hash';
const names=['coffee','water','fixed','cumulative_target_water','not_an_amount'];
// This whitelist is the only serialization path for storage and download.
function labelRecord(r){return {diagnostics_id:r.diagnostics_id,step_index:r.step_index,char_start:r.char_start,char_end:r.char_end,label:r.label};}
function serializeLabels(records){return JSON.stringify(records.map(labelRecord));}
let labels=[];let position=0;let picked='fixed';
const el=id=>document.getElementById(id);
try{const saved=JSON.parse(localStorage.getItem(storageKey)||'[]');labels=saved.filter(r=>names.includes(r.label)&&Number.isInteger(r.diagnostics_id)&&Number.isInteger(r.step_index)&&Number.isInteger(r.char_start)&&Number.isInteger(r.char_end)&&r.char_start>=0&&r.char_end>r.char_start&&items.some(i=>i.diagnostics_id===r.diagnostics_id&&i.step_index===r.step_index&&r.char_end<=i.text.length)).map(labelRecord);}catch(_){el('status').textContent='Saved labels unavailable.';}
function same(r,i){return r.diagnostics_id===i.diagnostics_id&&r.step_index===i.step_index;}
function matches(r,i){return same(r,i)&&(i.char_start===null||(r.char_start===i.char_start&&r.char_end===i.char_end));}
function save(){try{localStorage.setItem(storageKey,serializeLabels(labels));el('status').textContent='Labels saved locally.';}catch(_){el('status').textContent='Local save unavailable; export labels before closing.';}}
function draw(){
 const i=items[position];el('progress').textContent=items.length?Math.min(position+1,items.length)+' / '+items.length:'0 / 0';
 el('strata').textContent=${jsonEncode(corpusStrata)}.map(s=>s+': '+items.slice(0,position).filter(i=>i.strata.includes(s)).length+' / '+items.filter(i=>i.strata.includes(s)).length).join(' · ');
 for(const id of ['step','choices','chips','context','ai','aiTitle','hint','amounts'])el(id).replaceChildren();
 el('nothing').hidden=!i||i.char_start!==null;
 if(!i){el('step').textContent='Finished. Export your labels.';return;}
 el('amounts').textContent='Coffee: '+i.coffee+' g · Water: '+i.water+' ml · '+i.strata.join(', ');
 if(i.char_start===null){el('step').textContent=i.text;el('hint').textContent='Find missed amounts: select text and press 1–5.';}
 else{el('step').append(document.createTextNode(i.text.slice(0,i.char_start)));const mark=document.createElement('mark');mark.textContent=i.text.slice(i.char_start,i.char_end);el('step').append(mark,document.createTextNode(i.text.slice(i.char_end)));}
 picked=labels.find(r=>matches(r,i))?.label||({coffee:'coffee',water:'water',literal:'fixed'}[i.outcome]||'fixed');
 names.forEach((n,k)=>{const b=document.createElement('button');b.textContent=(k+1)+' '+n;b.className=n===picked?'active':'';b.onclick=()=>choose(k);el('choices').append(b);});
 if(i.char_start===null)labels.filter(r=>same(r,i)).forEach(r=>{const b=document.createElement('button');b.textContent=r.char_start+'–'+r.char_end+' '+r.label+' ×';b.onclick=()=>{labels=labels.filter(x=>x!==r);save();draw();};el('chips').append(b);});
 i.context.forEach(t=>{const li=document.createElement('li');li.textContent=t;el('context').append(li);});
 if(i.ai!==undefined){el('aiTitle').textContent='AI output, for reference';el('ai').textContent=i.ai;}
}
function choose(k){const i=items[position];if(!i)return;
 if(i.char_start===null){const selection=window.getSelection();if(!selection.rangeCount||selection.isCollapsed)return;const range=selection.getRangeAt(0),step=el('step');if(!step.contains(range.startContainer)||!step.contains(range.endContainer))return;const before=document.createRange();before.selectNodeContents(step);before.setEnd(range.startContainer,range.startOffset);const start=before.toString().length,end=start+range.toString().length;labels=labels.filter(r=>!(same(r,i)&&r.char_start===start&&r.char_end===end));labels.push(labelRecord({...i,char_start:start,char_end:end,label:names[k]}));selection.removeAllRanges();save();draw();}
 else{picked=names[k];[...el('choices').children].forEach((b,j)=>b.className=j===k?'active':'');}}
function advance(mode){const i=items[position];if(!i)return;
 if(mode==='skip'||mode==='nothing')labels=labels.filter(r=>!matches(r,i));
 else if(i.char_start!==null){labels=labels.filter(r=>!matches(r,i));labels.push(labelRecord({...i,label:picked}));}
 save();position++;draw();}
function back(){position=Math.max(0,position-1);draw();}
el('back').onclick=back;el('confirm').onclick=()=>advance('confirm');el('skip').onclick=()=>advance('skip');el('nothing').onclick=()=>advance('nothing');
document.addEventListener('keydown',e=>{if(e.ctrlKey||e.metaKey||e.altKey)return;if('12345'.includes(e.key)&&e.key.length===1){e.preventDefault();choose(Number(e.key)-1);}else if(e.key==='Enter'){e.preventDefault();advance('confirm');}else if(e.key==='Backspace'){e.preventDefault();back();}else if(e.key==='s'){e.preventDefault();advance('skip');}else if(e.key==='n'&&items[position]?.char_start===null){e.preventDefault();advance('nothing');}});
el('export').onclick=()=>{const url=URL.createObjectURL(new Blob([serializeLabels(labels)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='recipe_corpus_labels.json';a.click();URL.revokeObjectURL(url);};
draw();
</script></html>''';
}
