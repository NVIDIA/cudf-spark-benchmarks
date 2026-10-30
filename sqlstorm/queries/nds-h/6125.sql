WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), SupplierRegions AS (
    SELECT rs.s_suppkey, rs.s_name, r.r_name AS region_name, rs.total_cost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), HighCostSuppliers AS (
    SELECT s.*, RANK() OVER (PARTITION BY s.region_name ORDER BY s.total_cost DESC) AS cost_rank
    FROM SupplierRegions s
)
SELECT h.s_suppkey, h.s_name, r.r_name AS region_name, h.total_cost
FROM HighCostSuppliers h
JOIN region r ON h.region_name = r.r_name
WHERE h.cost_rank <= 5
ORDER BY r.r_name, h.total_cost DESC;
