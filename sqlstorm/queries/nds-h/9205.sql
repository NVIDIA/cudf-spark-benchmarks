WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
),
AverageSales AS (
    SELECT 
        region_name,
        total_sales,
        total_orders,
        total_sales / NULLIF(total_orders, 0) AS average_sales_per_order
    FROM 
        RegionalSales
)
SELECT 
    region_name,
    total_sales,
    total_orders,
    average_sales_per_order,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    AverageSales
ORDER BY 
    total_sales DESC;