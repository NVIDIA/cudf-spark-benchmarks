WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
), 

CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    cs.c_name AS customer_name,
    cs.total_order_value,
    rs.s_name AS top_supplier_name,
    rs.total_supply_cost
FROM 
    CustomerOrderDetails cs
LEFT JOIN 
    RankedSuppliers rs ON cs.c_custkey = rs.s_suppkey
WHERE 
    cs.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrderDetails)
ORDER BY 
    cs.total_order_value DESC
LIMIT 10;