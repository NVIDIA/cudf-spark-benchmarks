WITH price_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
top_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.total_supply_cost, 
        ps.supplier_count,
        ROW_NUMBER() OVER (ORDER BY ps.total_supply_cost DESC) AS rn
    FROM 
        part p
    JOIN 
        price_summary ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    COALESCE(tp.total_supply_cost, 0) AS total_supply_cost,
    tp.supplier_count,
    CASE 
        WHEN tp.supplier_count > 0 THEN 'Available' 
        ELSE 'Unavailable' 
    END AS status,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    top_parts tp
LEFT JOIN 
    lineitem l ON tp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey AND o.o_orderstatus = 'O'
WHERE 
    tp.rn <= 10
GROUP BY 
    tp.p_partkey, tp.p_name, tp.total_supply_cost, tp.supplier_count
ORDER BY 
    tp.total_supply_cost DESC;
