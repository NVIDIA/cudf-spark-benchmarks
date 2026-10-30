WITH RegionalSales AS (
    SELECT 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31' AND 
        l.l_shipdate >= DATE '1997-01-01' AND 
        l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
), 
TopRegions AS (
    SELECT 
        r_name, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)

SELECT 
    r.r_name AS region,
    r.total_sales AS sales_amount,
    COALESCE(t.sales_rank, 0) AS rank_within_region
FROM 
    RegionalSales r
LEFT JOIN 
    TopRegions t ON r.r_name = t.r_name
ORDER BY 
    r.total_sales DESC, 
    r.r_name;