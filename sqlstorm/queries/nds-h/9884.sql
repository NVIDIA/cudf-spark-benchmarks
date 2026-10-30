WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT rt.s_suppkey, rt.s_name, rt.total_supply_cost, RANK() OVER (PARTITION BY rt.s_nationkey ORDER BY rt.total_supply_cost DESC) AS rnk
    FROM RankedSuppliers rt
)
SELECT c.c_name, c.c_acctbal, ts.s_name, ts.total_supply_cost
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE ts.rnk <= 5
AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
ORDER BY ts.total_supply_cost DESC, c.c_name;