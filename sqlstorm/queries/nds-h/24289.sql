
WITH regional_supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, r.r_name,
           CASE 
               WHEN s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) THEN 'Above Average'
               ELSE 'Below Average'
           END AS acctbal_status
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
order_lineitem AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineprice
    FROM lineitem l
    GROUP BY l.l_orderkey
),
filtered_orders AS (
    SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
           ol.total_lineprice, 
           CASE 
               WHEN ol.total_lineprice IS NULL THEN 'No Line Items'
               ELSE 'Has Line Items'
           END AS lineitem_status
    FROM customer_orders co
    LEFT JOIN order_lineitem ol ON co.o_orderkey = ol.l_orderkey
)
SELECT rs.r_name, 
       COUNT(DISTINCT fo.c_custkey) AS customer_count,
       SUM(CASE WHEN fo.lineitem_status = 'Has Line Items' THEN fo.o_totalprice END) AS total_revenue_with_items,
       AVG(CASE WHEN fo.lineitem_status = 'No Line Items' THEN fo.o_totalprice END) AS avg_revenue_no_items,
       STRING_AGG(DISTINCT rs.s_name) AS supplier_names,
       COUNT(DISTINCT fo.o_orderkey) FILTER (WHERE fo.o_totalprice IS NOT NULL) AS non_null_orders,
       STRING_AGG(DISTINCT CASE WHEN fo.o_orderdate >= DATE '1998-10-01' - INTERVAL '30 days' THEN CAST(fo.o_orderkey AS STRING) END) AS recent_orders
FROM filtered_orders fo
JOIN regional_supplier rs ON fo.c_custkey = rs.s_suppkey 
GROUP BY rs.r_name
HAVING COUNT(DISTINCT fo.c_custkey) > 0
ORDER BY customer_count DESC;
