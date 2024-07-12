-- Step 1: Create the table
CREATE TABLE hospitals (
    id serial PRIMARY KEY,
	hid varchar,
	lat DOUBLE PRECISION, 
    long DOUBLE PRECISION,
    hname VARCHAR(100),
	hadd TEXT,
	hph VARCHAR(100),
	hspec TEXT,
	htype VARCHAR(100),
	huspec TEXT,
	hcspec TEXT,
    geom geometry(Point, 4326)
);

-- Step 2: Import the CSV data
COPY hospitals(id,hid,lat,long,hname,hadd,hph,hspec,htype,huspec,hcspec)
FROM 'Z:\IIRS PROJECT\CASE STUDY\data\healthcare.csv' DELIMITER ';' CSV HEADER;

-- Step 3: Update the geometry column
UPDATE hospitals
SET geom = ST_SetSRID(ST_MakePoint(Long, Lat), 4326);


--to update all the 3 layers to 4326
UPDATE hospitals SET geom = ST_SetSRID(geom, 4326);
UPDATE remain_ddn_villages SET geom = ST_SetSRID(geom, 4326);
UPDATE roads_clipped SET geom = ST_SetSRID(geom, 4326);


-- Example query to select and view combined geometries
SELECT layer_name, ST_AsText(geom) AS wkt_geometry
FROM combined_geometries;


SELECT COUNT(*) FROM hospitals;
SELECT COUNT(*) FROM roads_clipped;
SELECT COUNT(*) FROM remain_ddn_villages;



SELECT ST_SRID(geom) FROM hospitals LIMIT 1;
SELECT ST_SRID(geom) FROM remain_ddn_villages LIMIT 1;
SELECT ST_SRID(geom) FROM roads_clipped LIMIT 1;


DROP TABLE IF EXISTS combined_geometries;



-- Example to create combined_geometries table
CREATE TABLE combined_geometries AS
SELECT 'hospital' AS layer_name, geom FROM hospitals
UNION ALL
SELECT 'road' AS layer_name, geom FROM roads_clipped;
UNION ALL
SELECT 'village' AS layer_name, geom FROM remain_ddn_villages



-- Add source and target columns
ALTER TABLE roads_clipped ADD COLUMN IF NOT EXISTS source INTEGER;
ALTER TABLE roads_clipped ADD COLUMN IF NOT EXISTS target INTEGER;

-- Add cost columns
ALTER TABLE roads_clipped ADD COLUMN IF NOT EXISTS cost DOUBLE PRECISION;
ALTER TABLE roads_clipped ADD COLUMN IF NOT EXISTS reverse_cost DOUBLE PRECISION;

-- Populate the source and target columns
SELECT pgr_createTopology('roads_clipped', 0.0001, 'geom', 'gid');

-- Calculate costs (assuming cost is the length of the road segment)
UPDATE roads_clipped SET cost = ST_Length(geom);
UPDATE roads_clipped SET reverse_cost = cost;




/*-- Define start and end points
WITH start_point AS (
  SELECT gid, geom
  FROM roads_clipped
  ORDER BY geom <-> ST_SetSRID(ST_MakePoint(78.06539, 30.16897), 4326)
  LIMIT 1
),
end_point AS (
  SELECT gid, geom
  FROM roads_clipped
  ORDER BY geom <-> ST_SetSRID(ST_MakePoint(78,12299310000, 30,17979926000), 4326)
  LIMIT 1
)

-- Calculate the shortest path
SELECT seq, id1 AS node, id2 AS edge, cost, geom
FROM pgr_dijkstra(
  'SELECT gid, source, target, cost FROM roads_clipped',
  (SELECT gid FROM start_point),
  (SELECT gid FROM end_point),
  directed := false
) AS route
JOIN roads_clipped rd ON route.id2 = rd.id;
*/




-- Replace these with actual start and end coordinates
-- Example coordinates for start (longitude, latitude)
DO $$ 
DECLARE 
    start_lon FLOAT := 78.035;  -- Replace with actual start longitude
    start_lat FLOAT := 30.316;  -- Replace with actual start latitude
    end_lon FLOAT := 78.050;    -- Replace with actual end longitude
    end_lat FLOAT := 30.320;    -- Replace with actual end latitude
BEGIN
    -- Find the nearest nodes to the start and end points
    CREATE TEMP TABLE start_point AS
    SELECT gid, geom
    FROM roads_clipped
    ORDER BY geom <-> ST_SetSRID(ST_MakePoint(start_lon, start_lat), 4326)
    LIMIT 1;

    CREATE TEMP TABLE end_point AS
    SELECT gid, geom
    FROM roads_clipped
    ORDER BY geom <-> ST_SetSRID(ST_MakePoint(end_lon, end_lat), 4326)
    LIMIT 1;

    -- Calculate the shortest path
    CREATE TEMP TABLE shortest_path AS
    SELECT seq, node, edge, cost, geom
    FROM pgr_dijkstra(
        'SELECT gid AS id, source, target, cost FROM roads_clipped',
        (SELECT gid FROM start_point),
        (SELECT gid FROM end_point),
        directed := false
    ) AS route
    JOIN roads_clipped rd ON route.edge = rd.gid;

    -- Select the shortest path result
    SELECT * FROM shortest_path;
END $$;




