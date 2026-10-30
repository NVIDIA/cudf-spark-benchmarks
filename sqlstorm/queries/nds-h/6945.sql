WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
supplier_nation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    rp.p_name,
    rp.total_avail_qty,
    rp.total_supply_cost,
    sn.nation_name,
    COUNT(o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_price
FROM 
    ranked_parts rp
LEFT JOIN 
    lineitem l ON rp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier_nation sn ON l.l_suppkey = sn.s_suppkey
WHERE 
    rp.total_avail_qty > 1000
GROUP BY 
    rp.p_name, rp.total_avail_qty, rp.total_supply_cost, sn.nation_name
ORDER BY 
    rp.total_supply_cost DESC, rp.total_avail_qty ASC
LIMIT 10;
