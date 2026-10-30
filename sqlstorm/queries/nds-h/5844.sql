WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate <= DATE '1997-12-31'
),
HighValueLines AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS value
    FROM lineitem l
    JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE ro.order_rank <= 10
    GROUP BY l.l_orderkey
),
CustomerRegions AS (
    SELECT c.c_custkey, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT r.r_name, COUNT(DISTINCT hvl.l_orderkey) AS high_value_order_count, 
       SUM(hvl.value) AS total_revenue
FROM HighValueLines hvl
JOIN CustomerRegions cr ON cr.c_custkey = hvl.l_orderkey
JOIN region r ON cr.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_revenue DESC;