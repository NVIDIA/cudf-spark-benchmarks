
WITH RankedSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    COALESCE(cs.customer_name, 'No Orders') AS customer_name,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.avg_order_value, 0.00) AS avg_order_value,
    rs.supplier_name,
    rs.total_cost
FROM 
    CustomerOrderStats cs
FULL OUTER JOIN 
    RankedSuppliers rs ON cs.total_orders = rs.rank
WHERE 
    LENGTH(rs.supplier_name) > 5 
    OR cs.total_orders > 0
ORDER BY 
    cs.total_orders DESC, rs.total_cost DESC;
