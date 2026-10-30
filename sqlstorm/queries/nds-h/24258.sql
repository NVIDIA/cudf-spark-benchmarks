WITH  nation_sales AS (
    SELECT n.n_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY n.n_name
    
    UNION ALL
    
    SELECT n.n_name,
           SUM(l.l_extendedprice * (1 - l.l_discount) * 0.95) AS total_sales,
           NULLIF(COUNT(o.o_orderkey), 0) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount) * 0.95) DESC) AS sales_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    RIGHT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    FULL OUTER JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate IS NULL OR o.o_orderdate > '1997-12-31'
    GROUP BY n.n_name
)

SELECT ns.n_name,
       ns.total_sales,
       COALESCE(ns.order_count, 0) AS order_count,
       CASE 
           WHEN ns.total_sales IS NULL THEN 'No Sales' 
           WHEN ns.total_sales > 100000 THEN 'High Roller' 
           ELSE 'Average'
       END AS sales_category
FROM nation_sales ns
WHERE sales_rank <= 5
ORDER BY ns.total_sales DESC, ns.order_count ASC
LIMIT 10;