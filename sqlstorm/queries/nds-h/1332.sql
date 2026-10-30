WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS average_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionPerformance AS (
    SELECT
        n.n_regionkey,
        r.r_name,
        SUM(ss.total_sales) AS region_sales,
        COUNT(ss.order_count) AS total_orders
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
),
RankedRegions AS (
    SELECT 
        r.r_name,
        r.region_sales,
        r.total_orders,
        DENSE_RANK() OVER (ORDER BY r.region_sales DESC) AS sales_rank
    FROM 
        RegionPerformance r
)
SELECT 
    rr.r_name,
    rr.region_sales,
    rr.total_orders,
    CASE 
        WHEN rr.region_sales > 1000000 THEN 'High Performance'
        WHEN rr.region_sales BETWEEN 500000 AND 1000000 THEN 'Medium Performance'
        ELSE 'Low Performance'
    END AS performance_category
FROM 
    RankedRegions rr
WHERE 
    rr.sales_rank <= 5
ORDER BY 
    rr.region_sales DESC;

