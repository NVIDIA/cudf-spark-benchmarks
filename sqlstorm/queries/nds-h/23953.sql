
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
      AND o.o_orderdate >= '1997-01-01'
),

customer_summary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),

supplier_region_avg_cost AS (
    SELECT 
        s.s_nationkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),

products_info AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' by ', p.p_mfgr) AS full_description,
        COALESCE(p.p_retailprice, 0) AS effective_price
    FROM part p
    WHERE p.p_size IS NOT NULL 
      AND p.p_size BETWEEN 1 AND 100
),

combine_orders_lineitems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice) AS total_lineitem_price,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
)

SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    AVG(cs.total_spent) AS avg_customer_spent,
    COALESCE(MAX(oi.total_lineitem_price), 0) AS max_order_value,
    COUNT(DISTINCT oi.o_orderkey) AS total_orders_count,
    COALESCE(MAX(pr.effective_price), -1) AS max_effective_price,
    AVG(sr.avg_supplycost) AS avg_supplier_cost
FROM nation ns
LEFT JOIN customer_summary cs ON ns.n_nationkey = cs.c_custkey
LEFT JOIN combine_orders_lineitems oi ON cs.c_custkey = oi.o_orderkey
LEFT JOIN products_info pr ON pr.p_partkey = cs.c_custkey
LEFT JOIN supplier_region_avg_cost sr ON ns.n_nationkey = sr.s_nationkey
WHERE cs.order_count > 0
GROUP BY ns.n_name
HAVING COUNT(DISTINCT oi.o_orderkey) > 5
ORDER BY customer_count DESC, avg_customer_spent ASC;
