
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS CostRank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
BestSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name,
        rs.TotalCost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    WHERE rs.CostRank <= 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    oi.l_partkey,
    oi.l_quantity,
    oi.l_extendedprice,
    bs.s_name AS top_supplier
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem oi ON o.o_orderkey = oi.l_orderkey
JOIN BestSuppliers bs ON oi.l_suppkey = bs.s_suppkey
WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
AND oi.l_quantity > 10
ORDER BY c.c_custkey, o.o_orderdate, oi.l_partkey;
