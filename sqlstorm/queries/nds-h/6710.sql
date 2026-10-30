WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_quantity, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        stats.total_available_quantity, 
        stats.total_supply_value, 
        ROW_NUMBER() OVER (ORDER BY stats.total_supply_value DESC) AS rank
    FROM 
        SupplierStats stats
    JOIN 
        supplier s ON stats.s_suppkey = s.s_suppkey
)
SELECT 
    n.n_name AS nation_name, 
    SUM(o.o_totalprice) AS total_order_value, 
    COUNT(o.o_orderkey) AS total_orders,
    ts.total_available_quantity,
    ts.total_supply_value
FROM 
    orders o
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.total_available_quantity
WHERE 
    o.o_orderstatus = 'F'  
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    n.n_name, ts.total_available_quantity, ts.total_supply_value
ORDER BY 
    total_order_value DESC
LIMIT 10;