WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(ps.ps_partkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY COUNT(ps.ps_partkey) DESC, SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
top_parts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.supplier_count,
        rp.total_supply_cost
    FROM 
        ranked_parts rp
    WHERE 
        rp.rank <= 5
)
SELECT 
    tp.p_name,
    tp.p_brand,
    tp.supplier_count,
    tp.total_supply_cost,
    SUM(o.o_totalprice) AS total_orders_value,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    top_parts tp
LEFT JOIN 
    lineitem l ON tp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    tp.p_name, tp.p_brand, tp.supplier_count, tp.total_supply_cost
ORDER BY 
    total_orders_value DESC, supplier_count DESC;
