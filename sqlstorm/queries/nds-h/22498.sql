
WITH  cte_supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
cte_customer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           CASE 
               WHEN c.c_acctbal < 1000 THEN 'Low'
               WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END as cust_segment
    FROM customer c
),
cte_lineitem AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    WHERE l.l_shipdate > (DATE '1998-10-01' - INTERVAL '1 year')
    GROUP BY l.l_orderkey
),
cte_order_stats AS (
    SELECT o.o_orderkey, o.o_orderstatus, 
           CASE 
               WHEN o.o_totalprice > 10000 THEN 'High Value'
               ELSE 'Standard'
           END as order_type
    FROM orders o
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ps.ps_partkey) AS available_parts,
    SUM(cl.total_price) AS total_lineitem_price,
    COUNT(DISTINCT ct.c_custkey) FILTER (WHERE ct.cust_segment = 'High') AS high_value_customers,
    MAX(ct.c_acctbal) AS max_customer_balance,
    (SELECT COUNT(*) FROM part p WHERE p.p_retailprice > 
        (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    ) AS expensive_parts
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN cte_lineitem cl ON cl.l_orderkey = ps.ps_partkey
LEFT JOIN cte_customer ct ON ct.c_custkey = s.s_suppkey
LEFT JOIN cte_order_stats os ON os.o_orderkey = cl.l_orderkey
WHERE r.r_comment IS NOT NULL
GROUP BY r.r_name
HAVING SUM(cl.total_price) > 0 AND MAX(ct.c_acctbal) IS NOT NULL
ORDER BY r.r_name ASC;
