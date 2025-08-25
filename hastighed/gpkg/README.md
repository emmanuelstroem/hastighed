## GPKG
These GPKGS are the trimmed down from osm.pbf files downloaded for openstreetmap.

## Test query
These coordinates are for a motorway in Denmark.
```bash
python3 query_speed_limit.py --gpkg denmark.gpkg --lat 55.4474637 --lon 11.661 --radius 1 --max-radius 2
```

This Python script query should return the speed limit on that road.:
`Nearest road: highway=motorway, maxspeed_raw=130, maxspeed_kmh=130 km/h, distance_deg=7.83807e-06`

