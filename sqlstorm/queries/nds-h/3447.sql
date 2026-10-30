
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.total_orders,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_sales > 10000
)

SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_sales,
    ts.total_orders,
    CASE 
        WHEN ts.total_orders > 10 THEN 'High Activity'
        WHEN ts.total_orders BETWEEN 5 AND 10 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    TopSuppliers ts
WHERE 
    ts.sales_rank <= 10

UNION ALL

SELECT 
    NULL AS s_suppkey,
    'Overall Total' AS s_name,
    SUM(total_sales) AS total_sales,
    SUM(total_orders) AS total_orders,
    NULL AS activity_level
FROM 
    TopSuppliers
HAVING 
    COUNT(*) > 0;
