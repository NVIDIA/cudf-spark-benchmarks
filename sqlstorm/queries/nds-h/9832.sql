
WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '3 months'
),
HighValueSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderLineItems AS (
    SELECT li.l_orderkey, li.l_partkey, li.l_quantity, li.l_extendedprice, li.l_discount, li.l_tax
    FROM lineitem li
    JOIN RecentOrders ro ON li.l_orderkey = ro.o_orderkey
),
OrdersWithSupplierInfo AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name, 
           SUM(oli.l_extendedprice - (oli.l_extendedprice * oli.l_discount)) AS revenue,
           COUNT(DISTINCT oli.l_partkey) AS unique_parts
    FROM RecentOrders ro
    JOIN OrderLineItems oli ON ro.o_orderkey = oli.l_orderkey
    JOIN partsupp ps ON oli.l_partkey = ps.ps_partkey
    JOIN HighValueSuppliers hvs ON ps.ps_suppkey = hvs.ps_suppkey
    GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name
)
SELECT o.*,
       r.r_name AS region_name
FROM OrdersWithSupplierInfo o
JOIN customer c ON o.c_name = c.c_name
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE o.revenue > 5000
ORDER BY o.o_orderdate DESC, o.revenue DESC
LIMIT 50;
