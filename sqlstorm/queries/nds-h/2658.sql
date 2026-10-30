WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_nationkey
),
CombinedStats AS (
    SELECT 
        r.r_name,
        COALESCE(ss.total_parts_supplied, 0) AS total_parts_supplied,
        COALESCE(ss.total_available_quantity, 0) AS total_available_quantity,
        COALESCE(cs.total_orders, 0) AS total_orders,
        COALESCE(cs.total_revenue, 0) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        SupplierStats ss ON r.r_regionkey = ss.s_nationkey
    LEFT JOIN 
        CustomerOrderStats cs ON r.r_regionkey = cs.c_nationkey
)
SELECT 
    r_name,
    total_parts_supplied,
    total_available_quantity,
    total_orders,
    total_revenue,
    CASE 
        WHEN total_revenue > 0 THEN ROUND(total_available_quantity / total_revenue, 2)
        ELSE NULL 
    END AS availability_revenue_ratio,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    CombinedStats
WHERE 
    total_parts_supplied > 5 AND total_orders > 10
ORDER BY 
    revenue_rank
LIMIT 10;
