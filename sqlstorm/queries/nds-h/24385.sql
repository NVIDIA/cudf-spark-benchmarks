WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
supplier_summary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    ns.n_nationkey,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    MAX(rp.p_name) AS highest_priced_part,
    AVG(os.total_order_value) AS avg_order_value,
    SUM(CASE WHEN os.line_item_count > 5 THEN 1 ELSE 0 END) AS high_volume_orders
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    customer c ON ns.n_nationkey = c.c_nationkey
LEFT JOIN 
    supplier_summary ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN 
    ranked_parts rp ON rp.price_rank = 1
LEFT JOIN 
    order_summary os ON c.c_custkey = os.o_orderkey
WHERE 
    r.r_name IS NOT NULL
    AND (ss.total_supply_cost IS NOT NULL OR c.c_acctbal > 1000)
GROUP BY 
    r.r_name, ns.n_nationkey
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_supply_cost DESC, avg_order_value DESC;
