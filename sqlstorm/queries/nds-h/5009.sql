WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationInfo AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT si.s_suppkey, si.s_name, ni.n_name, ni.region_name, si.TotalCost
    FROM SupplierInfo si
    JOIN NationInfo ni ON si.s_nationkey = ni.n_nationkey
    ORDER BY si.TotalCost DESC
    LIMIT 10
)
SELECT ts.s_name, ts.region_name, ts.TotalCost, COUNT(DISTINCT o.o_orderkey) AS OrderCount
FROM TopSuppliers ts
JOIN lineitem l ON l.l_suppkey = ts.s_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY ts.s_suppkey, ts.s_name, ts.region_name, ts.TotalCost
ORDER BY ts.TotalCost DESC;