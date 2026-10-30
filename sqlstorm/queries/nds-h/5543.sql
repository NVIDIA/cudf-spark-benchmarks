WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, r.r_name, ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY ts.TotalCost DESC) AS Rank
    FROM RankedSuppliers ts
    JOIN supplier s ON ts.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT t.r_name AS RegionName, COUNT(*) AS SupplierCount, AVG(p.p_retailprice) AS AvgRetailPrice
FROM TopSuppliers t
JOIN lineitem l ON l.l_suppkey = t.s_suppkey
JOIN part p ON l.l_partkey = p.p_partkey
WHERE t.Rank <= 5 AND l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
GROUP BY t.r_name
ORDER BY SupplierCount DESC, AvgRetailPrice DESC;