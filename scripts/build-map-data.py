#!/usr/bin/env python3
"""Build public GeoJSON for the GitHub Pages incident map from *_UPLOAD.json."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROCESSED = ROOT / "evidence" / "processed"
OUT = ROOT / "docs" / "data" / "incidents.geojson"


def load_incidents() -> list[dict]:
    features: list[dict] = []
    for path in sorted(PROCESSED.glob("*_UPLOAD.json")):
        try:
            meta = json.loads(path.read_text())
        except (json.JSONDecodeError, OSError) as exc:
            print(f"skip {path.name}: {exc}", file=sys.stderr)
            continue

        youtube_url = meta.get("youtube_url") or meta.get("youtube", {}).get("url", "")
        if not youtube_url:
            continue

        incident = meta.get("incident") or {}
        lat = incident.get("latitude")
        lon = incident.get("longitude")
        if not lat or not lon:
            print(f"skip {path.name}: missing coordinates", file=sys.stderr)
            continue

        try:
            lat_f = float(lat)
            lon_f = float(lon)
        except (TypeError, ValueError):
            print(f"skip {path.name}: invalid coordinates", file=sys.stderr)
            continue

        yt = meta.get("youtube") or {}
        features.append(
            {
                "type": "Feature",
                "geometry": {"type": "Point", "coordinates": [lon_f, lat_f]},
                "properties": {
                    "incident_id": meta.get("incident_id", ""),
                    "base_name": meta.get("base_name", ""),
                    "title": yt.get("title", ""),
                    "recorded_utc": incident.get("recorded_utc", ""),
                    "recorded_bst": incident.get("recorded_bst", ""),
                    "youtube_url": youtube_url,
                    "map_url": incident.get("map_url", f"https://www.google.com/maps?q={lat},{lon}"),
                },
            }
        )
    return features


def main() -> int:
    features = load_incidents()
    collection = {"type": "FeatureCollection", "features": features}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(collection, indent=2) + "\n")
    print(f"Wrote {len(features)} incident(s) -> {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
