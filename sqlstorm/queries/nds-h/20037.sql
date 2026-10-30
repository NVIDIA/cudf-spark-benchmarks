WITH  supplier_credits AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_cost, 
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND o.o_orderdate >= '1996-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
ranked_orders AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY c_custkey ORDER BY net_revenue DESC) AS order_rank
    FROM customer_orders
),
filtered_orders AS (
    SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.net_revenue,
           COALESCE(credits.total_cost, 0) AS supplier_total_cost 
    FROM ranked_orders co
    LEFT JOIN supplier_credits credits ON co.o_orderkey % 10 = credits.s_suppkey % 10
    WHERE order_rank <= 5 AND net_revenue > (SELECT AVG(net_revenue) FROM ranked_orders)
)
SELECT fo.c_name, fo.o_orderkey, fo.o_orderdate, fo.net_revenue, 
       CASE 
           WHEN fo.supplier_total_cost IS NULL THEN 'No Supplier' 
           ELSE 'Has Supplier' 
       END AS supplier_status 
FROM filtered_orders fo
WHERE EXISTS (
    SELECT 1 
    FROM lineitem l 
    WHERE l.l_orderkey = fo.o_orderkey 
    AND l.l_shipmode IN ('TRUCK', 'SHIP')
)
AND fo.net_revenue - (SELECT AVG(net_revenue) FROM filtered_orders) > 10.00
ORDER BY fo.net_revenue DESC, fo.o_orderdate ASC
LIMIT 10 OFFSET 5;