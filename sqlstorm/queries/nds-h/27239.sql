WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sa.total_supply_cost,
        sa.total_parts_supplied
    FROM 
        SupplierAggregates sa
    JOIN 
        supplier s ON sa.s_suppkey = s.s_suppkey
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
)

SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost,
    ts.total_parts_supplied,
    r.r_name AS supplier_region,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = ts.s_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    ts.s_suppkey, ts.s_name, ts.total_supply_cost, ts.total_parts_supplied, r.r_name
ORDER BY 
    ts.total_supply_cost DESC;
