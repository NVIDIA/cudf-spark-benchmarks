WITH  supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
    WHERE s_acctbal IS NOT NULL
), 
top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name,
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
)
SELECT p.p_name, 
       COUNT(DISTINCT l.l_orderkey) AS total_orders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier_hierarchy sh ON sh.s_suppkey = l.l_suppkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_shipdate > '1995-01-01' AND 
      (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL) AND 
      p.p_retailprice BETWEEN 100 AND 500
GROUP BY p.p_name, r.r_regionkey
HAVING COUNT(DISTINCT l.l_orderkey) > 5
UNION ALL
SELECT p.p_name, 
       0 AS total_orders,
       SUM(ps.ps_supplycost * ps.ps_availqty) AS total_revenue,
       NULL AS revenue_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE (ps.ps_availqty IS NULL OR ps.ps_availqty > 10)
GROUP BY p.p_name
ORDER BY revenue_rank, total_revenue DESC;
