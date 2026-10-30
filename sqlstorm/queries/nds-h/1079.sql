WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_name,
    cs.order_count,
    cs.total_spent,
    sc.part_count,
    sc.total_supply_cost,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment
FROM 
    CustomerOrders cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierCosts sc ON sc.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_quantity > 20
        ORDER BY ps.ps_supplycost * ps.ps_availqty DESC 
        LIMIT 1
    )
WHERE 
    cs.order_count > 0
ORDER BY 
    total_spent DESC
LIMIT 10;
