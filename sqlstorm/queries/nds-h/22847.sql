
WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
), 
supplier_availability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availability,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), 
high_value_customers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 0 
            ELSE c.c_acctbal 
        END AS adjusted_acctbal
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING' 
      AND COALESCE(c.c_acctbal, 0) > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
nation_region AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        r.r_name 
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    n.r_name AS region_name,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(MAX(l.l_discount), 0) AS max_discount,
    CASE 
        WHEN SUM(l.l_quantity) = 0 THEN 'No Sales' 
        ELSE 'Sales Made' 
    END AS sales_status
FROM lineitem l
JOIN ranked_parts p ON l.l_partkey = p.p_partkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN supplier_availability sa ON p.p_partkey = sa.ps_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN high_value_customers c ON o.o_custkey = c.c_custkey
JOIN nation_region n ON s.s_nationkey = n.n_nationkey
WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND CURRENT_DATE
GROUP BY n.r_name, p.p_name
HAVING COUNT(DISTINCT c.c_custkey) > 5 
   OR SUM(l.l_discount) IS NOT NULL
ORDER BY region_name, total_quantity DESC;
