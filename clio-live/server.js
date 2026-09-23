const http=require("http");
const fs=require("fs");
const path=require("path");

const ROOT=path.join(__dirname,"public");
const STATE=path.join(__dirname,"state.json");
const TOKEN=process.env.EDIT_TOKEN||"";
const PORT=process.env.PORT||10000;

let state={revision:0,updatedAt:null,items:{},sessionNote:""};
try{state=JSON.parse(fs.readFileSync(STATE,"utf8"))}catch(e){}

function out(res,code,obj){
  res.writeHead(code,{"content-type":"application/json","cache-control":"no-store","access-control-allow-origin":"*"});
  res.end(JSON.stringify(obj));
}
function save(){try{fs.writeFileSync(STATE,JSON.stringify(state))}catch(e){}}
function body(req,cb){
  let s="";
  req.on("data",d=>{s+=d;if(s.length>1500000)req.destroy()});
  req.on("end",()=>{try{cb(JSON.parse(s||"{}"))}catch(e){cb(null)}});
}
function authed(req){return !!TOKEN && req.headers["x-edit-token"]===TOKEN;}

http.createServer((req,res)=>{
  if(req.method==="GET"&&req.url.startsWith("/api/state")) return out(res,200,state);

  if(req.method==="POST"&&req.url.startsWith("/api/auth")){
    return out(res,authed(req)?200:403,{ok:authed(req)});
  }

  if(req.method==="POST"&&req.url.startsWith("/api/patch")){
    if(!authed(req)) return out(res,403,{error:"read_only"});
    return body(req,b=>{
      if(!b) return out(res,400,{error:"bad_json"});
      if(b.id!=null){
        const id=String(b.id);
        state.items[id]=state.items[id]||{};
        if(["pass","fail","na",""].includes(b.status)) state.items[id].status=b.status;
        if(typeof b.note==="string") state.items[id].note=b.note.slice(0,2000);
      }
      if(typeof b.sessionNote==="string") state.sessionNote=b.sessionNote.slice(0,10000);
      state.revision=(state.revision||0)+1;
      state.updatedAt=new Date().toISOString();
      save();
      out(res,200,state);
    });
  }

  if(req.method==="POST"&&req.url.startsWith("/api/replace")){
    if(!authed(req)) return out(res,403,{error:"read_only"});
    return body(req,b=>{
      if(!b||typeof b!=="object") return out(res,400,{error:"bad_json"});
      const cleanItems={};
      if(b.items&&typeof b.items==="object"){
        for(const [id,v] of Object.entries(b.items)){
          if(!v||typeof v!=="object") continue;
          const x={};
          if(["pass","fail","na",""].includes(v.status)) x.status=v.status;
          if(typeof v.note==="string") x.note=v.note.slice(0,2000);
          cleanItems[String(id)]=x;
        }
      }
      state={
        revision:(state.revision||0)+1,
        updatedAt:new Date().toISOString(),
        items:cleanItems,
        sessionNote:typeof b.sessionNote==="string"?b.sessionNote.slice(0,10000):""
      };
      save();
      out(res,200,state);
    });
  }

  let p=req.url.split("?")[0];
  if(p==="/") p="/index.html";
  const file=path.normalize(path.join(ROOT,p));
  if(!file.startsWith(ROOT)){res.writeHead(403);return res.end("Forbidden")}
  fs.readFile(file,(err,data)=>{
    if(err){res.writeHead(404);return res.end("Not found")}
    const ext=path.extname(file);
    const types={".html":"text/html; charset=utf-8",".js":"application/javascript; charset=utf-8",".css":"text/css"};
    res.writeHead(200,{"content-type":types[ext]||"application/octet-stream","cache-control":ext===".html"?"no-cache":"public, max-age=120"});
    res.end(data);
  });
}).listen(PORT,()=>console.log("Clio checklist live on "+PORT));