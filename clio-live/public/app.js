const PHASES=[
"Ground rules before testing",
"Mechanic arrival and job scope",
"Drain, chemical clean and flush",
"Bleeding and stationary cooling-system validation",
"OBD, battery and charging checks before driving",
"Static whole-car checks before the first road test",
"First local road test — about 5–10 miles",
"First hot-idle and hot-restart check",
"Second road test — 20–30 miles mixed urban/A-road",
"Pre-motorway inspection",
"Motorway/dual-carriageway test — about 40–70 miles",
"Post-motorway heat-soak test",
"Overnight cold-soak setup",
"Day-two stone-cold inspection",
"Day-two extended mixed test — target 75–150 miles",
"Final full-cool check after the long test",
"Final 20–30 minute confirmation drive",
"Final handover record for Maxine"
];

const ITEMS=(window.CLIO_ITEMS||[]).map((x,i)=>({id:i+1,phase:x[0],text:x[1]}));
const qs=new URLSearchParams(location.search);
const wantsEditor=qs.get("edit")==="1";
let editor=false;
let token=localStorage.getItem("clio-edit-token")||"";
let state={revision:0,updatedAt:null,items:{},sessionNote:""};
let filter="all";
let syncing=false;
let lastRenderedRevision=-1;
let toastTimer=null;

const app=document.getElementById("app");

function esc(s){return String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));}
function count(){
  let pass=0,fail=0,na=0;
  for(const i of ITEMS){
    const s=state.items?.[i.id]?.status||"";
    if(s==="pass")pass++; else if(s==="fail")fail++; else if(s==="na")na++;
  }
  return {pass,fail,na,done:pass+fail+na,total:ITEMS.length};
}
function phaseStats(p){
  const xs=ITEMS.filter(i=>i.phase===p);let done=0,fail=0;
  xs.forEach(i=>{const s=state.items?.[i.id]?.status||"";if(s)done++;if(s==="fail")fail++;});
  return {done,total:xs.length,fail};
}
function showToast(msg){
  let t=document.getElementById("toast");
  if(!t){t=document.createElement("div");t.id="toast";t.className="toast";document.body.appendChild(t);}
  t.textContent=msg;t.classList.add("show");clearTimeout(toastTimer);toastTimer=setTimeout(()=>t.classList.remove("show"),1800);
}
function setSync(mode){
  syncing=mode==="busy";
  const el=document.getElementById("sync");
  if(!el)return;
  const dot=mode==="busy"?"busy":"live";
  let txt=mode==="busy"?"Saving…":"Live";
  if(state.updatedAt){const d=new Date(state.updatedAt);txt+=" · updated "+d.toLocaleTimeString([],{hour:"2-digit",minute:"2-digit",second:"2-digit"});}
  el.innerHTML='<span><i class="dot '+dot+'"></i>'+txt+'</span><span>rev '+(state.revision||0)+'</span>';
}
function backup(){
  if(!editor)return;
  try{localStorage.setItem("clio-live-backup",JSON.stringify(state));}catch(e){}
}
async function api(path,options={}){
  const headers={"content-type":"application/json",...(options.headers||{})};
  if(token)headers["x-edit-token"]=token;
  const res=await fetch(path,{...options,headers,cache:"no-store"});
  let data={};try{data=await res.json();}catch(e){}
  if(!res.ok)throw Object.assign(new Error(data.error||"request_failed"),{status:res.status});
  return data;
}
async function auth(t){
  token=t;
  try{
    await api("/api/auth",{method:"POST",body:"{}"});
    editor=true;localStorage.setItem("clio-edit-token",token);showToast("Checker mode unlocked");await refresh(true);return true;
  }catch(e){
    editor=false;token="";localStorage.removeItem("clio-edit-token");showToast("Wrong checker password");render(true);return false;
  }
}
async function maybeRestore(){
  if(!editor)return;
  const remoteCount=Object.keys(state.items||{}).length;
  let b=null;try{b=JSON.parse(localStorage.getItem("clio-live-backup")||"null");}catch(e){}
  const backupCount=b?Object.keys(b.items||{}).length:0;
  if(remoteCount===0 && backupCount>0){
    try{
      setSync("busy");
      state=await api("/api/replace",{method:"POST",body:JSON.stringify({items:b.items||{},sessionNote:b.sessionNote||""})});
      backup();showToast("Restored live state from this phone");
    }catch(e){}
  }
}
async function refresh(force=false){
  try{
    const fresh=await api("/api/state",{method:"GET"});
    const changed=force||fresh.revision!==state.revision||lastRenderedRevision<0;
    state=fresh;
    if(editor)backup();
    if(changed)render(true); else setSync("live");
  }catch(e){
    const el=document.getElementById("sync");
    if(el)el.innerHTML='<span><i class="dot"></i>Reconnecting…</span>';
  }
}
async function patch(payload){
  if(!editor)return;
  setSync("busy");
  try{
    state=await api("/api/patch",{method:"POST",body:JSON.stringify(payload)});
    backup();render(true);
  }catch(e){
    if(e.status===403){editor=false;localStorage.removeItem("clio-edit-token");token="";showToast("Editor session rejected");}
    await refresh(true);
  }
}
function setStatus(id,s){
  if(!editor)return;
  const old=state.items?.[id]?.status||"";
  const next=old===s?"":s;
  state.items=state.items||{};state.items[id]=state.items[id]||{};state.items[id].status=next;
  render(true);
  patch({id,status:next});
}
function saveNote(id,val){
  if(!editor)return;
  state.items=state.items||{};state.items[id]=state.items[id]||{};state.items[id].note=val;
  patch({id,note:val});
}
function saveSession(val){
  if(!editor)return;
  state.sessionNote=val;patch({sessionNote:val});
}
function setFilter(f){filter=f;render(true);}
function jumpPhase(v){
  const el=document.getElementById("phase-"+v);if(el)el.scrollIntoView({behavior:"smooth",block:"start"});
}
function copyLive(){
  const u=location.origin+"/";
  navigator.clipboard?.writeText(u).then(()=>showToast("Maxine's live-view link copied")).catch(()=>prompt("Copy this live-view URL:",u));
}
function exportResults(){
  const c=count();
  const lines=[
    "Renault Clio ST11 TZC — 48-Hour Live Validation",
    "Exported: "+new Date().toLocaleString(),
    "Progress: "+c.done+"/"+c.total+" | PASS "+c.pass+" | FAIL "+c.fail+" | N/A "+c.na,
    state.sessionNote?"Session note: "+state.sessionNote:"",
    ""
  ];
  ITEMS.forEach(i=>{
    const x=state.items?.[i.id]||{};const s=(x.status||"UNMARKED").toUpperCase();
    lines.push(i.id+". ["+s+"] "+i.text+(x.note?" — "+x.note:""));
  });
  const blob=new Blob([lines.join("\n")],{type:"text/plain"});
  const a=document.createElement("a");a.href=URL.createObjectURL(blob);a.download="clio-ST11-TZC-48h-results.txt";a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000);
}
function itemHtml(i){
  const x=state.items?.[i.id]||{};const s=x.status||"";
  if(filter==="fail"&&s!=="fail")return"";
  if(filter==="todo"&&s)return"";
  const cls=s?" "+s:"";
  const controls=editor
    ? '<div class="status-row">'+["pass","fail","na"].map(v=>'<button class="status '+v+(s===v?" active":"")+'" onclick="setStatus('+i.id+",'"+v+"'"+')">'+v.toUpperCase()+'</button>').join("")+'</div>'+
      '<textarea id="note-'+i.id+'" placeholder="Optional note / measurement / fault code…" onblur="saveNote('+i.id+',this.value)">'+esc(x.note||"")+'</textarea>'
    : '<div class="view-status">'+(s?'<span class="badge '+s+'">'+s.toUpperCase()+'</span>':'<span class="badge">UNMARKED</span>')+(x.note?'<span class="badge">NOTE</span>':"")+'</div>'+(x.note?'<textarea disabled>'+esc(x.note)+'</textarea>':"");
  return '<div class="card item'+cls+'"><div class="item-top"><div class="num">'+i.id+'.</div><div class="item-text">'+esc(i.text)+'</div></div>'+controls+'</div>';
}
function render(force=false){
  const active=document.activeElement;
  const activeId=active?.id||"";
  const activeValue=(active&&("value" in active))?active.value:null;
  const c=count();
  const mode=editor?"editor":wantsEditor?"viewer":"viewer";
  let login="";
  if(wantsEditor&&!editor){
    login='<div class="card editor-login"><div style="font-weight:850;margin-bottom:7px">Checker access</div><div class="login-row"><input id="tokenInput" type="password" autocomplete="current-password" placeholder="Private checker password"><button class="primary" onclick="auth(document.getElementById(\'tokenInput\').value)">Unlock</button></div><div class="login-msg">Maxine does not need this. The normal URL is read-only.</div></div>';
  }
  const visibleByPhase={};
  for(let p=0;p<PHASES.length;p++){
    const cards=ITEMS.filter(i=>i.phase===p).map(itemHtml).filter(Boolean).join("");
    if(cards)visibleByPhase[p]=cards;
  }
  const phases=Object.entries(visibleByPhase).map(([p,cards])=>{
    const st=phaseStats(+p);
    return '<section class="phase" id="phase-'+p+'"><div class="phase-head"><div class="phase-title">'+p+'. '+esc(PHASES[p])+'</div><div class="phase-count">'+st.done+'/'+st.total+(st.fail?' · '+st.fail+' fail':'')+'</div></div>'+cards+'</section>';
  }).join("");
  app.innerHTML='<div class="shell">'+
    '<header class="top"><div class="top-inner"><div class="kicker"><div><div class="title">Clio 48-Hour Live Validation</div><div class="vehicle">Renault Clio ST11 TZC · 377-point shakedown</div></div><span class="mode '+mode+'">'+(editor?"CHECKER MODE":"LIVE VIEW")+'</span></div>'+
    '<div class="progress-line"><div class="progress-bar" style="width:'+(c.done/c.total*100)+'%"></div></div>'+
    '<div class="stats"><div class="stat"><b>'+c.done+'</b><span>MARKED</span></div><div class="stat pass"><b>'+c.pass+'</b><span>PASS</span></div><div class="stat fail"><b>'+c.fail+'</b><span>FAIL</span></div><div class="stat"><b>'+c.na+'</b><span>N/A</span></div><div class="stat"><b>'+Math.round(c.done/c.total*100)+'%</b><span>DONE</span></div></div>'+
    '<div class="sync" id="sync"></div></div></header>'+
    '<main>'+login+
    (!editor?'<div class="warning-box">Live spectator view: this page updates automatically as checks are completed. It cannot change the checklist.</div>':'')+
    '<div class="toolbar"><div class="card controls"><div class="filter-row">'+
      '<button class="pill '+(filter==="all"?"active":"")+'" onclick="setFilter(\'all\')">All</button>'+
      '<button class="pill '+(filter==="fail"?"active":"")+'" onclick="setFilter(\'fail\')">Failures</button>'+
      '<button class="pill '+(filter==="todo"?"active":"")+'" onclick="setFilter(\'todo\')">Unmarked</button>'+
      '</div><select class="select" onchange="jumpPhase(this.value)"><option value="">Jump to phase…</option>'+PHASES.map((x,i)=>'<option value="'+i+'">'+i+'. '+esc(x)+'</option>').join("")+'</select></div>'+
    '<div class="card note-card"><label>Shared session / mechanic note</label><textarea id="sessionNote" '+(editor?'onblur="saveSession(this.value)"':'disabled')+' placeholder="Fault codes, mechanic notes, measurements…">'+esc(state.sessionNote||"")+'</textarea></div></div>'+
    (phases||'<div class="card empty">Nothing matches this filter.</div>')+
    '</main><div class="footerbar"><div class="footer-inner"><button class="secondary" onclick="copyLive()">Copy live link</button><button class="primary" onclick="exportResults()">Export results</button></div></div></div>';
  lastRenderedRevision=state.revision;
  setSync(syncing?"busy":"live");
  if(activeId&&activeValue!==null){
    const n=document.getElementById(activeId);if(n){n.value=activeValue;try{n.focus()}catch(e){}}
  }
}
async function boot(){
  if(ITEMS.length!==377)console.warn("Expected 377 checks, found",ITEMS.length);
  if(wantsEditor&&token){
    try{await api("/api/auth",{method:"POST",body:"{}"});editor=true;}catch(e){editor=false;token="";localStorage.removeItem("clio-edit-token");}
  }
  await refresh(true);
  await maybeRestore();
  render(true);
  setInterval(()=>{if(!syncing)refresh(false)},2000);
}
boot();