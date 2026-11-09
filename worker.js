const json=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{"content-type":"application/json; charset=utf-8","cache-control":"no-store"}});
async function requireAdmin(request,env){
  const auth=request.headers.get("Authorization")||"";
  const token=auth.startsWith("Bearer ")?auth.slice(7):"";
  const base=(env.SUPABASE_URL||"").replace(/\/$/,"");
  const key=env.SUPABASE_ANON_KEY||"";
  if(!token||!base||!key) throw new Error("Admin API is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY as Worker variables.");
  const userRes=await fetch(base+"/auth/v1/user",{headers:{apikey:key,Authorization:"Bearer "+token}});
  if(!userRes.ok) throw new Error("Your admin session is invalid or expired.");
  const user=await userRes.json();
  const roleRes=await fetch(base+"/rest/v1/admin_users?user_id=eq."+encodeURIComponent(user.id)+"&select=user_id",{headers:{apikey:key,Authorization:"Bearer "+token}});
  if(!roleRes.ok) throw new Error("Could not verify your administrator role.");
  const roles=await roleRes.json();
  if(!roles.length) throw new Error("Administrator access is required.");
  return user;
}
async function createVimeoUpload(request,env){
  await requireAdmin(request,env);
  if(!env.VIMEO_ACCESS_TOKEN) return json({error:"Vimeo is not configured. Add VIMEO_ACCESS_TOKEN as a Worker secret."},503);
  let body;try{body=await request.json()}catch{return json({error:"Invalid JSON body."},400)}
  const size=Number(body.size);
  const name=String(body.name||"ANIME STREAM episode").trim().slice(0,120);
  const description=String(body.description||"").trim().slice(0,2000);
  if(!Number.isSafeInteger(size)||size<1) return json({error:"A valid video file size is required."},400);
  const vimeo=await fetch("https://api.vimeo.com/me/videos",{method:"POST",headers:{Authorization:"bearer "+env.VIMEO_ACCESS_TOKEN,"Content-Type":"application/json",Accept:"application/vnd.vimeo.*+json;version=3.4"},body:JSON.stringify({upload:{approach:"tus",size},name,description,privacy:{view:"unlisted",embed:"public",download:false}})});
  const data=await vimeo.json().catch(()=>({}));
  if(!vimeo.ok) return json({error:data.error||data.developer_message||"Vimeo could not create an upload session.",details:data.error_code||vimeo.status},vimeo.status>=500?502:400);
  if(data.upload?.approach!=="tus"||!data.upload?.upload_link||!data.uri) return json({error:"Vimeo did not return a resumable upload link."},502);
  return json({upload_link:data.upload.upload_link,uri:data.uri,name:data.name||name});
}
export default {async fetch(request,env){
  const url=new URL(request.url);
  if(url.pathname==="/api/vimeo/create-upload"){
    if(request.method!=="POST") return json({error:"Method not allowed."},405);
    try{return await createVimeoUpload(request,env)}catch(e){return json({error:e.message||"Upload authorization failed."},401)}
  }
  if(url.pathname.startsWith("/api/")) return json({error:"API route not found."},404);
  return env.ASSETS.fetch(request);
}};
