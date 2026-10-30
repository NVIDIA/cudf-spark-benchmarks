WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 
           o.o_custkey, CAST(o.o_orderkey AS STRING) AS path
    FROM orders o
    WHERE o.o_orderdate >= '1995-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 
           o.o_custkey, CONCAT(oh.path, '>', o.o_orderkey)
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
)

SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE l.l_returnflag = 'N'
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
    AND (c.c_acctbal IS NOT NULL OR c.c_mktsegment = 'BUILDING')
GROUP BY n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC
LIMIT 10;