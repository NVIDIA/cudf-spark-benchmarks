
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
DistinctRegions AS (
    SELECT DISTINCT n.n_name AS nation_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT ds.region_name, ds.nation_name, COUNT(*) AS SupplierCount
    FROM RankedSuppliers rs
    JOIN DistinctRegions ds ON rs.s_name LIKE '%' || ds.nation_name || '%'
    GROUP BY ds.region_name, ds.nation_name
)
SELECT region_name, nation_name, SupplierCount
FROM TopSuppliers
WHERE SupplierCount > 1
ORDER BY region_name, SupplierCount DESC;
