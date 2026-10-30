WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) as OrderLevel
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
    UNION ALL
    SELECT oh.o_orderkey, oh.o_orderstatus, oh.o_totalprice, oh.o_orderdate, 
           oh.OrderLevel + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
)
SELECT
    c.c_custkey,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_line_price,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(l.l_shipdate) AS earliest_ship_date,
    COUNT(DISTINCT CASE 
        WHEN l.l_tax IS NULL THEN 'No Tax' 
        ELSE 'Tax Applied' 
    END) AS tax_status_count
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
GROUP BY c.c_custkey, c.c_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC
LIMIT 100;