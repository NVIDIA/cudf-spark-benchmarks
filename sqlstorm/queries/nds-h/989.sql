WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierInfo AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
AggregatedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_quantity) AS avg_quantity, 
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count, 
       SUM(ali.total_revenue) AS total_revenue,
       AVG(si.total_avail_qty) AS average_supply_avail,
       MAX(ali.avg_quantity) AS max_avg_quantity
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN RankedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN AggregatedLineItems ali ON o.o_orderkey = ali.l_orderkey
LEFT JOIN SupplierInfo si ON si.ps_partkey IN (
    SELECT ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
WHERE o.order_rank <= 5 
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_revenue DESC, r.r_name ASC;
