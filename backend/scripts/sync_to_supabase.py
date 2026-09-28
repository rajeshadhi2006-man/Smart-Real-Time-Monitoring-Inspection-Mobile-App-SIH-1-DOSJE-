import os
import sys
import json

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_dir)

from app.services.supabase_service import supabase_db

cache_path = os.path.join(backend_dir, 'face_templates_cache.json')
with open(cache_path, 'r') as f:
    cache = json.load(f)

print(f"Syncing cached templates to Supabase...")
for user_key, data in cache.items():
    user_id = data.get('user_id', user_key)
    officer_id = data.get('officer_id')
    full_name = data.get('full_name', 'Field Officer')
    embedding = data.get('embedding')
    quality_score = data.get('quality_score', 0.95)

    record = {
        'user_id': user_id,
        'officer_id': officer_id,
        'full_name': full_name,
        'embedding': embedding,
        'model_version': 'ArcFace-MobileFaceNet-512',
        'quality_score': quality_score
    }
    try:
        supabase_db.client.table('user_face_embeddings').upsert(record, on_conflict='user_id').execute()
        print(f" - Synced {user_id} ({officer_id}) to Supabase!")
    except Exception as e:
        print(f" - Error syncing {user_id}: {e}")

# Verify count now
res = supabase_db.client.table('user_face_embeddings').select('user_id, officer_id, model_version, quality_score, created_at').execute()
print(f"\nSUCCESS: Total face records in Supabase Cloud: {len(res.data)}")
for r in res.data:
    print(" ->", r)
