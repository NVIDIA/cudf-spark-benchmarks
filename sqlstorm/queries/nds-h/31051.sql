
WITH  cte_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
cte_customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
top_nations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) >= 5
)
SELECT sup.s_name, 
       cust.c_name, 
       cust.total_spent, 
       COALESCE(r.region_count, 0) AS region_count,
       AVG(co.sales_rank) AS avg_sales_rank
FROM cte_suppliers sup
JOIN cte_customer_orders cust ON sup.s_nationkey = cust.c_custkey
LEFT JOIN (
    SELECT n.n_regionkey, COUNT(*) AS region_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey
) AS r ON r.n_regionkey = sup.s_nationkey
JOIN (
    SELECT o.o_orderkey,
           COUNT(*) OVER (PARTITION BY o.o_orderkey) AS sales_rank
    FROM orders o
) AS co ON co.o_orderkey = cust.o_orderkey
WHERE sup.rnk <= 10
GROUP BY sup.s_name, cust.c_name, cust.total_spent, r.region_count
ORDER BY cust.total_spent DESC, sup.s_name, cust.c_name;
