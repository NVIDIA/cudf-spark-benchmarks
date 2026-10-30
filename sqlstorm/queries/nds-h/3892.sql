WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        c.c_custkey
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.num_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT 
    cr.c_name, 
    cr.total_spent, 
    COALESCE(rs.total_avail_qty, 0) AS total_avail_qty,
    CASE 
        WHEN cr.customer_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    CustomerRanked cr
LEFT JOIN 
    RankedSuppliers rs ON cr.c_custkey = rs.s_suppkey
WHERE 
    cr.num_orders > 5 
ORDER BY 
    cr.total_spent DESC