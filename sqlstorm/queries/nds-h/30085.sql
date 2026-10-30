WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= 10000
),
nation_sales AS (
    SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY n.n_name
),
branch_sales AS (
    SELECT n.n_name, COUNT(*) AS num_orders, AVG(l.l_extendedprice) AS avg_price
    FROM nation n
    LEFT JOIN orders o ON n.n_nationkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY n.n_name
),
combined_sales AS (
    SELECT ns.n_name, ns.total_sales, bs.num_orders, bs.avg_price
    FROM nation_sales ns
    FULL OUTER JOIN branch_sales bs ON ns.n_name = bs.n_name
)
SELECT cs.n_name, COALESCE(cs.total_sales, 0) AS total_sales, 
       COALESCE(cs.num_orders, 0) AS num_orders, 
       COALESCE(cs.avg_price, 0) AS avg_price,
       ROW_NUMBER() OVER (ORDER BY COALESCE(cs.total_sales, 0) DESC) AS sales_rank
FROM combined_sales cs
WHERE COALESCE(cs.total_sales, 0) > 50000
ORDER BY sales_rank
LIMIT 10;