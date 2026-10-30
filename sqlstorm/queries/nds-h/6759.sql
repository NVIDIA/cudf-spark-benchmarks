
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, total_supply_cost
    FROM RankedSuppliers s
    WHERE total_supply_cost > (
        SELECT AVG(total_supply_cost) FROM RankedSuppliers
    )
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierOrderStats AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           MAX(o.o_orderdate) AS last_order_date
    FROM lineitem l
    JOIN RecentOrders o ON l.l_orderkey = o.o_orderkey
    JOIN HighValueSuppliers h ON l.l_suppkey = h.s_suppkey
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
)
SELECT h.s_suppkey, h.s_name, s.total_revenue, s.last_order_date
FROM HighValueSuppliers h
JOIN SupplierOrderStats s ON h.s_suppkey = s.l_suppkey
ORDER BY s.total_revenue DESC, s.last_order_date DESC
LIMIT 10;
