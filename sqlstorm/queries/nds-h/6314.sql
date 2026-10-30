WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationCosts AS (
    SELECT n.n_nationkey, n.n_name, SUM(sd.total_cost) AS national_cost
    FROM SupplierDetails sd
    JOIN nation n ON sd.s_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
RegionCosts AS (
    SELECT r.r_regionkey, r.r_name, SUM(nc.national_cost) AS region_cost
    FROM NationCosts nc
    JOIN nation n ON nc.n_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rc.r_name, rc.region_cost
FROM RegionCosts rc
WHERE rc.region_cost > (
    SELECT AVG(region_cost) FROM RegionCosts
)
ORDER BY rc.region_cost DESC
LIMIT 10;
