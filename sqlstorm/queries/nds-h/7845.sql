WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
), 
SalesRanked AS (
    SELECT 
        region,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    region, 
    total_sales, 
    order_count, 
    sales_rank
FROM 
    SalesRanked
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_rank;