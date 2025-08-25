#!/usr/bin/env python3
"""
Query the nearest road and its speed limit from a GeoPackage.
Usage:
  python query_speed_limit.py --gpkg denmark_speedlimits.gpkg --lat 55.6761 --lon 12.5683

Notes:
- Requires GDAL Python bindings (osgeo). This is typically installed with GDAL.
- The GeoPackage is assumed to have a layer named 'roads' with columns: highway, maxspeed, and geometry column 'geom' in EPSG:4326.
"""
import argparse
import sys
from math import radians, cos
from urllib import request, parse
import json
import os
import re
import time

try:
    from osgeo import ogr, osr
    ogr.UseExceptions()
except Exception as e:
    print("GDAL Python bindings not available. Please install GDAL with Python support.")
    sys.exit(1)


def haversine_deg_scale(lat: float):
    """Approximate degree lengths for a given latitude to build a search box.
    Returns (deg_per_meter_lon, deg_per_meter_lat).
    """
    # 1 deg lat ~= 111_320 m; 1 deg lon ~= 111_320 * cos(lat)
    deg_per_meter_lat = 1.0 / 111320.0
    deg_per_meter_lon = 1.0 / (111320.0 * max(0.0001, cos(radians(lat))))
    return deg_per_meter_lon, deg_per_meter_lat


DRIVABLE = {
    "motorway", "trunk", "primary", "secondary", "tertiary",
    "unclassified", "residential", "service", "living_street",
    "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link"
}


def parse_maxspeed(val: str | None) -> tuple[str | None, float | None]:
    """Return (raw, numeric_kmh) from a maxspeed string.
    Handles forms like '50', '50 km/h', '30 mph', 'signals', 'DK:urban'.
    """
    if not val:
        return None, None
    raw = val.strip()
    s = raw.lower().replace(" ", "")
    # mph
    if s.endswith("mph"):
        try:
            num = float(''.join(ch for ch in s[:-3] if (ch.isdigit() or ch == '.')))
            return raw, num * 1.60934
        except Exception:
            return raw, None
    # km/h explicit
    if s.endswith("km/h"):
        try:
            num = float(''.join(ch for ch in s[:-4] if (ch.isdigit() or ch == '.')))
            return raw, num
        except Exception:
            return raw, None
    # plain number
    if any(ch.isdigit() for ch in s):
        try:
            num = float(''.join(ch for ch in s if (ch.isdigit() or ch == '.')))
            return raw, num
        except Exception:
            return raw, None
    # country codes like dk:urban
    if ":" in s:
        return raw, None
    return raw, None


def dk_fallback_speed(highway: str | None) -> float | None:
    """Heuristic fallbacks for Denmark when maxspeed missing (km/h)."""
    if not highway:
        return None
    h = highway.lower()
    if h == "motorway":
        return 130.0
    if h in {"trunk"}:  # expressways often 110
        return 110.0
    if h in {"primary", "secondary", "tertiary", "unclassified"}:
        return 80.0
    if h in {"residential"}:
        return 50.0
    if h in {"living_street"}:
        return 15.0
    if h in {"service"}:
        return 30.0
    return None


PRIORITY_TIERS = [
    {"motorway", "motorway_link"},
    {"trunk", "trunk_link"},
    {"primary", "primary_link"},
    {"secondary", "secondary_link"},
    {"tertiary", "tertiary_link"},
    {"unclassified", "residential", "service", "living_street"},
]


def find_nearest(gpkg_path: str, lat: float, lon: float, radius_m: float = 200.0, max_radius_m: float = 2000.0, drivable_only: bool = True, prefer_tagged: bool = True, prefer_motorways: bool = True):
    ds = ogr.Open(gpkg_path)
    if ds is None:
        raise RuntimeError(f"Failed to open GeoPackage: {gpkg_path}")

    layer = ds.GetLayerByName("roads")
    if layer is None:
        raise RuntimeError("Layer 'roads' not found in GeoPackage")

    # Build point geometry (WGS84)
    srs = osr.SpatialReference()
    srs.ImportFromEPSG(4326)
    point = ogr.Geometry(ogr.wkbPoint)
    point.AssignSpatialReference(srs)
    point.AddPoint(lon, lat)

    best = None  # (distance_deg, feature)

    # Ensure we will search at least once even if radius_m > max_radius_m
    if radius_m > max_radius_m:
        max_radius_m = radius_m
    # Iteratively expand search radius until we find candidates
    cur_radius = radius_m
    while best is None and cur_radius <= max_radius_m:
        dlon, dlat = haversine_deg_scale(lat)
        dx = dlon * cur_radius
        dy = dlat * cur_radius
        minx, miny = lon - dx, lat - dy
        maxx, maxy = lon + dx, lat + dy
        layer.SetSpatialFilterRect(minx, miny, maxx, maxy)

        # 1) Try priority tiers (motorway first) if requested
        found_any = False
        if prefer_motorways:
            for tier in PRIORITY_TIERS:
                cats = ",".join([f"'{c}'" for c in sorted(tier)])
                where_list = [f"highway IN ({cats}) AND maxspeed IS NOT NULL"] if prefer_tagged else []
                where_list.append(f"highway IN ({cats})")
                best_in_tier = None
                for where in where_list:
                    layer.SetAttributeFilter(where)
                    layer.ResetReading()
                    for feat in layer:
                        geom = feat.GetGeometryRef()
                        if geom is None:
                            continue
                        try:
                            dist = geom.Distance(point)
                        except Exception:
                            continue
                        if best_in_tier is None or dist < best_in_tier[0]:
                            best_in_tier = (dist, feat.Clone())
                    if best_in_tier is not None:
                        break
                if best_in_tier is not None:
                    best = best_in_tier
                    found_any = True
                    break

        # 2) Drivable filter fallback (prefer tagged first)
        if best is None:
            drivable_cats = ",".join([f"'{c}'" for c in sorted(DRIVABLE)])
            where_list = [f"highway IN ({drivable_cats}) AND maxspeed IS NOT NULL"] if prefer_tagged else []
            where_list.append(f"highway IN ({drivable_cats})")
            for where in where_list:
                layer.SetAttributeFilter(where)
                layer.ResetReading()
                best_local = None
                for feat in layer:
                    geom = feat.GetGeometryRef()
                    if geom is None:
                        continue
                    try:
                        dist = geom.Distance(point)
                    except Exception:
                        continue
                    if best_local is None or dist < best_local[0]:
                        best_local = (dist, feat.Clone())
                if best_local is not None:
                    best = best_local
                    found_any = True
                    break

        # 3) Any feature fallback
        if best is None:
            layer.SetAttributeFilter(None)
            layer.ResetReading()
            best_local = None
            for feat in layer:
                geom = feat.GetGeometryRef()
                if geom is None:
                    continue
                try:
                    dist = geom.Distance(point)
                except Exception:
                    continue
                if best_local is None or dist < best_local[0]:
                    best_local = (dist, feat.Clone())
            if best_local is not None:
                best = best_local
                found_any = True

        # Clear filters for next radius iteration
        layer.SetAttributeFilter(None)
        layer.SetSpatialFilter(None)
        if best is None:
            cur_radius *= 2.0

    layer.SetSpatialFilter(None)

    if best is None:
        return None

    dist_deg, feat = best
    highway = feat.GetField("highway")
    maxspeed_raw = feat.GetField("maxspeed")
    raw, kmh = parse_maxspeed(maxspeed_raw)
    if kmh is None:
        kmh = dk_fallback_speed(highway)
    props = {
        "highway": highway,
        "maxspeed_raw": raw,
        "maxspeed_kmh": kmh,
        "distance_deg": dist_deg,
    }
    return props


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--gpkg", default="denmark_speedlimits.gpkg")
    parser.add_argument("--lat", type=float, required=False)
    parser.add_argument("--lon", type=float, required=False)
    parser.add_argument("--address", type=str, help="Free-form address to geocode (uses Nominatim)")
    parser.add_argument("--radius", type=float, default=500.0, help="Initial search radius in meters")
    parser.add_argument("--max-radius", dest="max_radius", type=float, default=5000.0, help="Maximum search radius in meters")
    parser.add_argument("--no-prefer-motorways", action="store_true", help="Disable motorway-first priority")
    args = parser.parse_args()

    lat = args.lat
    lon = args.lon
    if args.address and (lat is None or lon is None):
        # Build candidate queries
        q_orig = args.address.strip()
        # Normalize house number ranges like "6-14" -> "6"
        q_simple = re.sub(r"\b(\d+)\s*-\s*\d+\b", r"\1", q_orig)
        ascii_map = str.maketrans({"æ":"ae","ø":"oe","å":"aa","Æ":"Ae","Ø":"Oe","Å":"Aa"})
        candidates = []
        for base in {q_orig, q_simple, q_orig.translate(ascii_map), q_simple.translate(ascii_map)}:
            candidates.append(base)
            if "denmark" not in base.lower():
                candidates.append(base + ", Denmark")

        # Geocoder providers: Nominatim then Photon
        def geocode_nominatim(q: str):
            email = os.environ.get("NOMINATIM_EMAIL", "example@example.com")
            ua = f"speedlimit-tools/1.0 ({email})"
            url = "https://nominatim.openstreetmap.org/search?" + parse.urlencode({
                "q": q,
                "format": "json",
                "limit": 1,
                "addressdetails": 0,
                "countrycodes": "dk",
            })
            req = request.Request(url, headers={"User-Agent": ua})
            with request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            if data:
                return float(data[0]["lat"]), float(data[0]["lon"]) 
            return None

        def geocode_photon(q: str):
            # Photon by komoot
            url = "https://photon.komoot.io/api/?" + parse.urlencode({
                "q": q,
                "limit": 1,
                "lang": "da",
            })
            req = request.Request(url, headers={"User-Agent": "speedlimit-tools/1.0"})
            with request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            feats = data.get("features") or []
            if feats:
                coords = feats[0]["geometry"]["coordinates"]
                return float(coords[1]), float(coords[0])
            return None

        success = False
        for q in candidates:
            for provider in (geocode_nominatim, geocode_photon):
                try:
                    res = provider(q)
                    if res:
                        lat, lon = res
                        print(f"Geocoded address to lat={lat}, lon={lon}")
                        success = True
                        break
                except Exception:
                    time.sleep(0.5)
                    continue
            if success:
                break
        if not success:
            print("Address not found after retries.")
            sys.exit(3)

    if lat is None or lon is None:
        print("Must provide either --lat/--lon or --address")
        sys.exit(2)

    res = find_nearest(
        args.gpkg,
        lat,
        lon,
        radius_m=args.radius,
        max_radius_m=args.max_radius,
        prefer_motorways=not args.no_prefer_motorways,
    )
    if res is None:
        print("No nearby road found within search radius.")
        sys.exit(2)
    hwy = res.get('highway')
    raw = res.get('maxspeed_raw')
    kmh = res.get('maxspeed_kmh')
    dist = res.get('distance_deg')
    raw_str = str(raw) if raw is not None else 'None'
    kmh_str = f"{kmh:.0f} km/h" if kmh is not None else 'unknown'
    print(f"Nearest road: highway={hwy}, maxspeed_raw={raw_str}, maxspeed_kmh={kmh_str}, distance_deg={dist:.6g}")
