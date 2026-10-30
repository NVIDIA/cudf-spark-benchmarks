WITH SupplierSales AS (
    SELECT 
        s.s_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_nationkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
CombinedData AS (
    SELECT 
        r.r_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(co.total_orders, 0) AS total_orders,
        COALESCE(co.total_revenue, 0) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        SupplierSales ss ON r.r_regionkey = ss.s_nationkey
    LEFT JOIN 
        CustomerOrders co ON r.r_regionkey = co.c_nationkey
)
SELECT 
    r_name,
    total_sales,
    total_orders,
    total_revenue,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank,
    CASE 
        WHEN total_sales > 100000 THEN 'High'
        WHEN total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    CombinedData
WHERE 
    total_orders > (SELECT AVG(total_orders) FROM CustomerOrders)
ORDER BY 
    total_sales DESC;
