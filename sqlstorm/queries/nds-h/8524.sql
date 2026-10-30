
WITH HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate <= DATE '1997-01-01'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, 
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSupplierJoin AS (
    SELECT hvo.o_orderkey, s.s_suppkey, s.s_name, hvo.total_value
    FROM HighValueOrders hvo
    JOIN lineitem l ON hvo.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN SupplierDetails d ON s.s_suppkey = d.s_suppkey
)
SELECT os.o_orderkey, os.s_suppkey, os.s_name, 
       ROUND(os.total_value, 2) AS order_value, 
       d.total_parts, 
       ROUND(d.total_cost, 2) AS supplier_total_cost
FROM OrderSupplierJoin os
JOIN SupplierDetails d ON os.s_suppkey = d.s_suppkey
ORDER BY os.o_orderkey, d.total_cost DESC;
