
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier AS s
    JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (ORDER BY TotalCost DESC) AS SupplierRank
    FROM RankedSuppliers AS s
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    ts.s_name AS TopSupplier
FROM customer AS c
JOIN orders AS o ON c.c_custkey = o.o_custkey
JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN TopSuppliers AS ts ON l.l_suppkey = ts.s_suppkey
WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, ts.s_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY TotalRevenue DESC;
