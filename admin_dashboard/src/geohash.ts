// Pure TypeScript GeoHash decoder and bounding box calculator

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

export interface GeoBox {
  minLat: number;
  maxLat: number;
  minLon: number;
  maxLon: number;
}

export function decodeGeoHash(geohash: string): GeoBox {
  let even = true;
  let latInterval = [-90.0, 90.0];
  let lonInterval = [-180.0, 180.0];

  for (let i = 0; i < geohash.length; i++) {
    const cd = BASE32.indexOf(geohash[i].toLowerCase());
    if (cd === -1) continue;

    for (const mask of [16, 8, 4, 2, 1]) {
      if (even) {
        const mid = (lonInterval[0] + lonInterval[1]) / 2.0;
        if ((cd & mask) !== 0) {
          lonInterval[0] = mid;
        } else {
          lonInterval[1] = mid;
        }
      } else {
        const mid = (latInterval[0] + latInterval[1]) / 2.0;
        if ((cd & mask) !== 0) {
          latInterval[0] = mid;
        } else {
          latInterval[1] = mid;
        }
      }
      even = !even;
    }
  }

  return {
    minLat: latInterval[0],
    maxLat: latInterval[1],
    minLon: lonInterval[0],
    maxLon: lonInterval[1],
  };
}
