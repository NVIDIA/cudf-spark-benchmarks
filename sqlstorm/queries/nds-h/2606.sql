WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
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
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        n.n_name, r.r_name
), 
TopNations AS (
    SELECT 
        nation_name, 
        region_name, 
        total_sales,
        RANK() OVER(PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    tn.region_name, 
    tn.nation_name, 
    tn.total_sales,
    COALESCE((SELECT AVG(total_sales) FROM TopNations WHERE region_name = tn.region_name), 0) AS avg_sales_in_region,
    CASE 
        WHEN total_sales > 0.8 * COALESCE((SELECT AVG(total_sales) FROM TopNations WHERE region_name = tn.region_name), 0) THEN 'Above Average'
        WHEN total_sales < 0.2 * COALESCE((SELECT AVG(total_sales) FROM TopNations WHERE region_name = tn.region_name), 0) THEN 'Below Average'
        ELSE 'Average'
    END AS sales_category
FROM 
    TopNations tn
WHERE 
    tn.sales_rank <= 5
ORDER BY 
    tn.region_name, 
    tn.total_sales DESC;
