WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
),

RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
),

HighValueSuppliers AS (
    SELECT 
        r.r_name,
        ns.n_name,
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales
    FROM 
        RankedSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        ss.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
)

SELECT 
    hvs.r_name,
    hvs.n_name,
    hvs.s_name,
    hvs.total_sales,
    COALESCE(hvs.total_sales * 0.1, 0) AS estimated_profit,
    CASE 
        WHEN hvs.total_sales > 100000 THEN 'High Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    HighValueSuppliers hvs
LEFT JOIN 
    (SELECT 
         COUNT(*) AS supplier_count 
     FROM 
         supplier) sp ON 1=1
WHERE 
    hvs.total_sales IS NOT NULL
ORDER BY 
    hvs.total_sales DESC;
