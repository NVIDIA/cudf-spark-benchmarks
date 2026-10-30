
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
MaxOrderValue AS (
    SELECT 
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        orders o
)
SELECT 
    co.c_name,
    co.total_orders,
    co.total_spent,
    rs.supplier_rank,
    rs.total_supply_value,
    CASE 
        WHEN co.total_spent > (SELECT max_order_value FROM MaxOrderValue) THEN 'Above Max Order'
        ELSE 'Within Range'
    END AS order_status
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedSuppliers rs ON co.total_orders > 10
WHERE 
    co.total_spent IS NOT NULL
ORDER BY 
    co.total_spent DESC
LIMIT 50;
