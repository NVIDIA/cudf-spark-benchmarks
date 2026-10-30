WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopRegions AS (
    SELECT n.n_regionkey, SUM(sd.TotalCost) AS RegionCost
    FROM nation n
    JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    GROUP BY n.n_regionkey
    ORDER BY RegionCost DESC
    LIMIT 5
)
SELECT r.r_name, tr.RegionCost
FROM region r
JOIN TopRegions tr ON r.r_regionkey = tr.n_regionkey
ORDER BY tr.RegionCost DESC;
