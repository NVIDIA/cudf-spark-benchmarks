WITH  supplier_cte AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           STRING_AGG(p.p_name, ', ') AS part_names
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING SUM(ps.ps_availqty) > 1000
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY c.c_custkey, c.c_name
),
ranked_orders AS (
    SELECT co.c_custkey, co.c_name, co.order_count, 
           co.avg_order_value,
           RANK() OVER (PARTITION BY co.order_count ORDER BY co.avg_order_value DESC) AS rnk
    FROM customer_orders co
)
SELECT sr.s_name, sr.s_acctbal, 
       CASE 
           WHEN r.rnk IS NULL THEN 'No Orders'
           ELSE CAST(r.avg_order_value AS STRING) 
       END AS avg_order_value,
       COALESCE(NULLIF(sr.part_names, ''), 'No Parts') AS part_names
FROM supplier_cte sr
FULL OUTER JOIN ranked_orders r ON sr.s_suppkey = r.c_custkey
WHERE sr.s_acctbal > 100.00 OR r.avg_order_value IS NOT NULL
ORDER BY sr.s_name, r.order_count DESC NULLS LAST;