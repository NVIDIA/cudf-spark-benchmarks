WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT s.s_nationkey, s.s_name, r.r_name, s.TotalSupplyCost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.TotalSupplyCost DESC) AS SupplierRank
    FROM RankedSuppliers s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT t.s_nationkey, n.n_name, t.s_name, t.r_name, t.TotalSupplyCost
FROM TopSuppliers t
JOIN nation n ON t.s_nationkey = n.n_nationkey
WHERE t.SupplierRank <= 3
ORDER BY n.n_name, t.TotalSupplyCost DESC;
