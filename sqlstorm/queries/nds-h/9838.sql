WITH RegionSales AS (
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
        o.o_orderdate BETWEEN DATE '1993-01-01' AND DATE '1993-12-31'
    GROUP BY 
        r.r_name
), SalesRanked AS (
    SELECT 
        region_name,
        total_sales,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionSales
)
SELECT 
    region_name,
    total_sales,
    total_orders,
    sales_rank
FROM 
    SalesRanked
WHERE 
    sales_rank <= 5
ORDER BY 
    sales_rank;
