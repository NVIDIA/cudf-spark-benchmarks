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
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    avg(total_sales) AS avg_sales,
    sum(total_orders) AS total_orders,
    MAX(sales_rank) AS highest_rank
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.total_orders > 5 
    AND rs.total_sales IS NOT NULL
GROUP BY 
    r.r_name, n.n_name
UNION ALL
SELECT 
    'Global Average' AS region,
    NULL AS nation,
    AVG(total_sales) AS avg_sales,
    SUM(total_orders) AS total_orders,
    NULL AS highest_rank
FROM 
    RankedSuppliers
WHERE 
    sales_rank IS NOT NULL;
