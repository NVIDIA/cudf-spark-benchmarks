WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT sd.s_suppkey, sd.s_name, r.r_name, sd.TotalSupplyCost,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY sd.TotalSupplyCost DESC) AS Rank
    FROM SupplierDetails sd
    JOIN nation n ON sd.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ts.r_name, ts.s_name, ts.TotalSupplyCost
FROM TopSuppliers ts
WHERE ts.Rank <= 5
ORDER BY ts.r_name, ts.TotalSupplyCost DESC;
