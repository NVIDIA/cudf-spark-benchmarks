WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
CombinedStats AS (
    SELECT 
        cs.c_name,
        cs.total_orders,
        cs.total_revenue,
        rs.s_name AS top_supplier
    FROM 
        CustomerOrderStats cs
    LEFT JOIN 
        RankedSuppliers rs ON cs.total_revenue > 100000 AND rs.rn = 1
)
SELECT 
    c.c_name AS customer_name,
    c.total_orders,
    c.total_revenue,
    COALESCE(c.top_supplier, 'No Supplier') AS top_supplier
FROM 
    CombinedStats c
WHERE 
    c.total_revenue > 5000
ORDER BY 
    c.total_revenue DESC, 
    c.total_orders DESC;
