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
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
        AND o.o_orderstatus IN ('F', 'P') 
    GROUP BY 
        r.r_name
), RankBySales AS (
    SELECT 
        region_name,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    r.region_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(r.total_orders, 0) AS total_orders,
    CASE 
        WHEN r.sales_rank IS NULL THEN 'No Sales'
        ELSE CONCAT('Rank: ', r.sales_rank)
    END AS sales_status
FROM 
    (SELECT DISTINCT r_name FROM region) AS regions
LEFT JOIN 
    RankBySales r ON regions.r_name = r.region_name
ORDER BY 
    total_sales DESC NULLS LAST;