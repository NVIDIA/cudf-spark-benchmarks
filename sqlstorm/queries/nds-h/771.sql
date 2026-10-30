WITH RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        r.*, 
        RANK() OVER (ORDER BY r.total_sales DESC) AS sales_rank
    FROM 
        RegionSales r
)
SELECT 
    r.r_name AS region_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(r.order_count, 0) AS order_count,
    CASE 
        WHEN r.sales_rank <= 5 THEN 'Top Seller'
        WHEN r.sales_rank IS NULL THEN 'No Sales'
        ELSE 'Regular Seller' 
    END AS sales_category
FROM 
    RankedSales r
RIGHT JOIN 
    region rg ON r.r_name = rg.r_name
ORDER BY 
    r.sales_rank NULLS LAST;