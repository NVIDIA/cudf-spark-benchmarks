
WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS order_depth
    FROM orders
    WHERE o_orderstatus IS NOT NULL
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus, 
           oh.order_depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
)
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ': ', CAST(p.p_retailprice AS STRING)), '; ') AS product_info,
    CASE 
        WHEN AVG(l.l_discount) IS NULL THEN 'No Discounts'
        WHEN AVG(l.l_discount) < 0.05 THEN 'Low Discounts'
        ELSE 'High Discounts'
    END AS discount_category,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE c.c_acctbal > 0
  AND o.o_orderdate BETWEEN '1995-01-01' AND '1996-01-01'
  AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY c.c_custkey, c.c_name, c.c_nationkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(total_revenue)
    FROM (
        SELECT SUM(l1.l_extendedprice * (1 - l1.l_discount)) AS total_revenue
        FROM customer c1
        JOIN orders o1 ON c1.c_custkey = o1.o_custkey
        JOIN lineitem l1 ON o1.o_orderkey = l1.l_orderkey
        GROUP BY c1.c_custkey
    ) AS subquery
)
ORDER BY revenue_rank, total_revenue DESC
LIMIT 10;
