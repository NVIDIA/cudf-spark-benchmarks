WITH regional_supplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_nationkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_nationkey, s.s_suppkey
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
line_item_stats AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_linenumber) AS distinct_line_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        MAX(l.l_discount) AS max_discount,
        AVG(l.l_tax) AS average_tax
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.region_name,
    cs.c_name,
    cs.total_order_value,
    lis.distinct_line_count,
    lis.total_extended_price,
    (CASE 
        WHEN lis.max_discount IS NULL THEN 'No Discount'
        ELSE CAST(lis.max_discount * 100 AS DECIMAL(5, 2)) || '%' 
    END) AS max_discount_percentage,
    (CASE 
        WHEN cs.order_count = 0 THEN 'No Orders'
        ELSE CAST(ROUND(cs.total_order_value / NULLIF(cs.order_count, 0), 2) AS STRING)
    END) AS avg_order_value,
    (SELECT 
        COUNT(DISTINCT ps_partkey) 
     FROM 
        partsupp ps 
     WHERE 
        ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
    ) AS high_supply_cost_part_count
FROM 
    regional_supplier r
JOIN 
    customer_order_summary cs ON r.s_nationkey = cs.c_custkey
LEFT OUTER JOIN 
    line_item_stats lis ON cs.c_custkey = lis.l_orderkey 
WHERE 
    r.total_supply_cost = (SELECT MAX(total_supply_cost) FROM regional_supplier)
    AND (cs.total_order_value IS NOT NULL OR cs.order_count > 0)
ORDER BY 
    r.region_name, cs.c_name;
