
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01'
),
supplier_part_stats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_brand) AS distinct_brands
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
abnormal_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'NO BALANCE'
            WHEN c.c_acctbal < 0 THEN 'OVERDRAWN'
            ELSE 'BALANCED'
        END AS balance_status
    FROM customer c
    WHERE c.c_mktsegment IN ('BUILDING', 'HOUSEHOLD')
),
order_totals AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_order_value
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY l.l_orderkey
)
SELECT 
    ra.o_orderkey,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(sp.total_supply_value, 0) AS supply_value,
    ot.net_order_value,
    ra.order_rank,
    CASE 
        WHEN ra.order_rank IS NOT NULL AND ra.order_rank <= 10 THEN 'TOP ORDER'
        ELSE 'OTHER ORDER'
    END AS order_classification
FROM ranked_orders ra
LEFT JOIN abnormal_customers c ON c.c_custkey = ra.o_orderkey
LEFT JOIN supplier_part_stats sp ON sp.ps_suppkey = ra.o_orderkey
LEFT JOIN order_totals ot ON ot.l_orderkey = ra.o_orderkey
WHERE 
    (ra.o_totalprice IS NOT NULL OR ot.net_order_value IS NOT NULL)
    AND (sp.distinct_brands > 1 OR sp.total_supply_value < 1000)
ORDER BY ra.order_rank DESC, supply_value DESC;
