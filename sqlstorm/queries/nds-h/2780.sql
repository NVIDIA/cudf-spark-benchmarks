WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),

CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT
    cs.c_name,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(s.total_sales, 0) AS total_sales,
    CASE 
        WHEN cs.last_order_date IS NOT NULL AND cs.total_orders > 0 THEN 'Active'
        ELSE 'Inactive' 
    END AS customer_status
FROM 
    CustomerOrders cs
LEFT JOIN 
    (SELECT 
        p_partkey, 
        total_sales 
     FROM 
        RankedSales 
     WHERE 
        sales_rank = 1) s ON cs.c_custkey = s.p_partkey 
WHERE 
    cs.total_spent > 1000 OR s.total_sales IS NOT NULL
ORDER BY 
    cs.total_spent DESC, cs.c_name;
