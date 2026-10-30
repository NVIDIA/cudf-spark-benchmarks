WITH regional_summary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
part_supplier_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
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
)
SELECT 
    r.region_name,
    p.p_name,
    p.supplier_count,
    p.total_supply_value,
    c.c_name AS customer_name,
    c.total_order_value,
    c.order_count
FROM 
    regional_summary r
FULL OUTER JOIN 
    part_supplier_details p ON r.nation_count = p.supplier_count
LEFT JOIN 
    customer_order_summary c ON p.total_supply_value > c.total_order_value
WHERE 
    (p.p_name LIKE 'A%' OR p.p_name LIKE 'B%')
    AND (c.order_count IS NULL OR c.total_order_value > 1000)
ORDER BY 
    r.region_name, p.total_supply_value DESC, c.total_order_value ASC;
