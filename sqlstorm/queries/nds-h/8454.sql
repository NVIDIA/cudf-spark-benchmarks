WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationInfo AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS RegionName
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT sd.s_suppkey, sd.s_name, ni.n_name AS NationName, sd.TotalSupplyCost
    FROM SupplierDetails sd
    JOIN NationInfo ni ON sd.s_nationkey = ni.n_nationkey
    ORDER BY sd.TotalSupplyCost DESC
    LIMIT 10
)
SELECT ts.NationName, COUNT(DISTINCT ts.s_suppkey) AS SupplierCount, SUM(ts.TotalSupplyCost) AS AggregateCost
FROM TopSuppliers ts
GROUP BY ts.NationName
ORDER BY AggregateCost DESC;
