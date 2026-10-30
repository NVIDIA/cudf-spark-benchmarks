
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierOrderStats AS (
    SELECT hs.nation_name, COUNT(DISTINCT ho.o_orderkey) AS order_count,
           AVG(ho.order_value) AS avg_order_value
    FROM HighValueOrders ho
    JOIN RankedSuppliers hs ON ho.o_custkey = hs.s_suppkey
    GROUP BY hs.nation_name
)
SELECT nation_name, order_count, avg_order_value
FROM SupplierOrderStats
WHERE order_count > 5
ORDER BY avg_order_value DESC;
