WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, ro.total_revenue
    FROM RankedOrders ro
    JOIN orders o ON ro.o_orderkey = o.o_orderkey
    WHERE ro.revenue_rank <= 10
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT t.o_orderkey, t.o_orderdate, t.total_revenue, 
       COUNT(DISTINCT sp.ps_suppkey) AS unique_suppliers,
       SUM(sp.total_availqty) AS total_available_quantity
FROM TopOrders t
JOIN lineitem l ON t.o_orderkey = l.l_orderkey
JOIN SupplierParts sp ON l.l_partkey = sp.ps_partkey
GROUP BY t.o_orderkey, t.o_orderdate, t.total_revenue
ORDER BY t.total_revenue DESC;
