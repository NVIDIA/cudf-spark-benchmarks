
WITH OrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           c.c_nationkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_nationkey
),
SupplierTotal AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(st.total_supply_cost) AS total_cost
    FROM SupplierTotal st
    JOIN supplier s ON st.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
)
SELECT os.o_orderkey, 
       os.total_revenue, 
       ts.s_name AS top_supplier,
       ts.total_cost
FROM OrderSummary os
JOIN lineitem l ON os.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE os.line_count > 1
ORDER BY os.total_revenue DESC;
