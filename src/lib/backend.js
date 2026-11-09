const url=import.meta.env.VITE_SUPABASE_URL?.replace(/\/$/,'');
const anon=import.meta.env.VITE_SUPABASE_ANON_KEY;
export const backendReady=Boolean(url&&anon);
function headers(token){return {'apikey':anon,'Authorization':`Bearer ${token||anon}`,'Content-Type':'application/json'};}
export async function signIn(email,password){
 if(!backendReady)throw new Error('Admin backend is not configured. Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in Cloudflare.');
 const r=await fetch(url+'/auth/v1/token?grant_type=password',{method:'POST',headers:headers(),body:JSON.stringify({email,password})});
 const data=await r.json();if(!r.ok)throw new Error(data.msg||data.message||'Sign-in failed');return data;
}
export async function getAdmin(token,userId){
 const r=await fetch(url+'/rest/v1/admin_users?user_id=eq.'+encodeURIComponent(userId)+'&select=user_id',{headers:headers(token)});
 if(!r.ok)throw new Error('Could not verify admin role. Check database policies.');
 return (await r.json()).length>0;
}
export async function listEpisodes(token){
 const r=await fetch(url+'/rest/v1/episodes?select=*&order=created_at.desc',{headers:headers(token)});
 const data=await r.json();if(!r.ok)throw new Error(data.message||'Could not load episodes');return data;
}
export async function saveEpisode(token,episode){
 const r=await fetch(url+'/rest/v1/episodes',{method:'POST',headers:{...headers(token),'Prefer':'return=representation'},body:JSON.stringify(episode)});
 const data=await r.json();if(!r.ok)throw new Error(data.message||'Could not publish episode');return data;
}
export async function removeEpisode(token,id){
 const r=await fetch(url+'/rest/v1/episodes?id=eq.'+encodeURIComponent(id),{method:'DELETE',headers:headers(token)});
 if(!r.ok)throw new Error('Could not delete episode');
}
export async function importAniListLinks(token,anime){
 const rows=(anime.streamingEpisodes||[]).filter(x=>x.url).map((ep,i)=>({
  anime_id:anime.id,anime_title:anime.title?.english||anime.title?.romaji||'Anime',
  episode_number:i+1,episode_title:ep.title||'Episode '+(i+1),
  source_type:'provider_link',video_url:ep.url,provider_name:ep.site||'Official provider',
  status:'published',rights_confirmed:false
 }));
 if(!rows.length)return 0;
 const r=await fetch(url+'/rest/v1/episodes',{method:'POST',headers:{...headers(token),'Prefer':'return=minimal'},body:JSON.stringify(rows)});
 const data=await r.json().catch(()=>null);if(!r.ok)throw new Error(data?.message||'Could not import provider links');return rows.length;
}

export async function listPublicEpisodes(animeId){
 if(!backendReady)return [];
 const r=await fetch(url+'/rest/v1/episodes?anime_id=eq.'+encodeURIComponent(animeId)+'&status=eq.published&select=*&order=episode_number.asc',{headers:headers()});
 if(!r.ok)return [];
 return await r.json();
}
