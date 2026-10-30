
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
MaxValueSupplier AS (
    SELECT 
        ss.s_name,
        ss.total_parts,
        ss.total_value,
        ROW_NUMBER() OVER (ORDER BY ss.total_value DESC) AS rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_value > 0
)
SELECT 
    co.c_name AS customer_name,
    co.order_count,
    COALESCE(mvs.s_name, 'No Supplier') AS top_supplier,
    COALESCE(mvs.total_value, 0) AS supplier_value
FROM 
    CustomerOrders co
LEFT JOIN 
    MaxValueSupplier mvs ON co.order_count >= 5
WHERE 
    co.total_spent > 1000
ORDER BY 
    co.total_spent DESC
LIMIT 10;
