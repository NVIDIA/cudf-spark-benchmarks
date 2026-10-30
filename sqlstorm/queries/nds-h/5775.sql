WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationCost AS (
    SELECT n.n_nationkey, n.n_name, SUM(sd.total_cost) AS nation_cost
    FROM SupplierDetails sd
    JOIN nation n ON sd.s_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
RegionCost AS (
    SELECT r.r_regionkey, r.r_name, SUM(nc.nation_cost) AS region_cost
    FROM NationCost nc
    JOIN nation n ON nc.n_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rc.r_name, rc.region_cost
FROM RegionCost rc
JOIN (
    SELECT r_regionkey, MAX(region_cost) AS max_cost
    FROM RegionCost
    GROUP BY r_regionkey
) max_rc ON rc.r_regionkey = max_rc.r_regionkey AND rc.region_cost = max_rc.max_cost
ORDER BY rc.r_name;
