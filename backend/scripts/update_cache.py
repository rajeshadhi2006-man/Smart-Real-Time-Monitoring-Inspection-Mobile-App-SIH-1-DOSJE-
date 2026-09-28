import os
import sys
import json

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_dir)

from app.services.arcface_service import arcface_engine
from tests.test_arcface_pipeline import create_synthetic_face

face_a = create_synthetic_face(seed=101, brightness=130)
emb_a = arcface_engine.detect_and_encode_face(face_a)

face_b = create_synthetic_face(seed=202, brightness=130)
emb_b = arcface_engine.detect_and_encode_face(face_b)

if emb_a is None or emb_b is None:
    print("Error: Could not encode faces")
    sys.exit(1)

cache = {
    'officer@surveillance.gov.in': {
        'user_id': 'officer@surveillance.gov.in',
        'officer_id': 'OFF-001',
        'full_name': 'Field Inspector Rajesh',
        'embedding': emb_a.tolist(),
        'model_version': 'arcface_v1',
        'quality_score': 0.95
    },
    'OFF-001': {
        'user_id': 'officer@surveillance.gov.in',
        'officer_id': 'OFF-001',
        'full_name': 'Field Inspector Rajesh',
        'embedding': emb_a.tolist(),
        'model_version': 'arcface_v1',
        'quality_score': 0.95
    },
    'rajeshadhi2006@gmail.com': {
        'user_id': 'rajeshadhi2006@gmail.com',
        'officer_id': 'INSP-042',
        'full_name': 'Rajesh Adhi',
        'embedding': emb_b.tolist(),
        'model_version': 'arcface_v1',
        'quality_score': 0.95
    }
}

cache_file = os.path.join(backend_dir, 'face_templates_cache.json')
with open(cache_file, 'w') as f:
    json.dump(cache, f, indent=2)

print('SUCCESS: Updated face_templates_cache.json with 512-D embeddings.')
print('Dimensions:', len(emb_a.tolist()))
