
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        total_order_value DESC
    LIMIT 5
)
SELECT 
    tr.r_name,
    ss.s_name,
    ss.total_available,
    ss.total_supply_value
FROM 
    SupplierStats ss
JOIN 
    partsupp ps ON ss.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    TopRegions tr ON ss.s_suppkey = p.p_partkey
JOIN 
    nation n ON tr.n_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
WHERE 
    ss.total_supply_value > 1000000
ORDER BY 
    tr.r_name, ss.total_supply_value DESC;
