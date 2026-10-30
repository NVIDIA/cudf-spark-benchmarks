
WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
nation_supplier AS (
    SELECT 
        n.n_nationkey, 
        s.s_suppkey, 
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, s.s_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0 AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
)
SELECT 
    n.n_name AS r_name, 
    ps.p_name, 
    cs.order_count,
    cs.total_spent,
    ns.total_cost,
    NULLIF(cs.total_spent, 0) AS adjusted_spent,
    CASE 
        WHEN cs.order_count > 0 THEN cs.total_spent / cs.order_count 
        ELSE 0 
    END AS avg_spent_per_order,
    CASE 
        WHEN ns.total_cost IS NULL THEN 'No Suppliers'
        ELSE 'Suppliers Available'
    END AS supplier_status
FROM ranked_parts ps
JOIN nation n ON n.n_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'ASIA' LIMIT 1)
FULL OUTER JOIN customer_orders cs ON n.n_nationkey = (SELECT c_nationkey FROM customer GROUP BY c_nationkey ORDER BY COUNT(*) DESC LIMIT 1)
LEFT JOIN nation_supplier ns ON n.n_nationkey = ns.n_nationkey
WHERE ps.price_rank <= 10 AND (cs.order_count IS NULL OR cs.total_spent > 1000)
ORDER BY n.n_name, ps.p_retailprice DESC
LIMIT 50;
