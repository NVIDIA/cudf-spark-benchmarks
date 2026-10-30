
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_acctbal > 5000
        LIMIT 1
    )
    WHERE o.o_orderdate > DATE '1998-10-01' - INTERVAL '1 year'
)
SELECT 
    p.p_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    r.r_name AS region_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem li ON li.l_partkey = p.p_partkey
LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_retailprice > 100
    AND li.l_shipdate IS NOT NULL
    AND (s.s_comment LIKE '%urgent%' OR n.n_comment IS NULL)
GROUP BY p.p_name, r.r_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY total_orders DESC, total_revenue DESC
LIMIT 10;
