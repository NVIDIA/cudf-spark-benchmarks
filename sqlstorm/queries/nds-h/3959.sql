WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
), CTEWithRank AS (
    SELECT 
        nation_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
), TopNations AS (
    SELECT 
        nation_name,
        total_sales,
        order_count
    FROM 
        CTEWithRank
    WHERE 
        sales_rank <= 5
)
SELECT 
    t.nation_name,
    t.total_sales,
    t.order_count,
    COALESCE((SELECT AVG(total_sales) FROM TopNations), 0) AS avg_sales,
    CASE 
        WHEN t.total_sales > COALESCE((SELECT AVG(total_sales) FROM TopNations), 0) 
        THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS sales_comparison
FROM 
    TopNations t
LEFT JOIN 
    region r ON r.r_name = t.nation_name
ORDER BY 
    t.total_sales DESC;