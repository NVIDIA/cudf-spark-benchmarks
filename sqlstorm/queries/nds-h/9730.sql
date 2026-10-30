WITH MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM o_orderdate) AS order_year,
        EXTRACT(MONTH FROM o_orderdate) AS order_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        r_name AS region_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON s.s_suppkey = l.l_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        order_year, order_month, region_name
),
TopRegions AS (
    SELECT 
        region_name,
        SUM(total_sales) AS region_sales
    FROM 
        MonthlySales
    GROUP BY 
        region_name
    ORDER BY 
        region_sales DESC
    LIMIT 5
)
SELECT 
    ms.order_year,
    ms.order_month,
    ms.region_name,
    ms.total_sales
FROM 
    MonthlySales ms
JOIN 
    TopRegions tr ON ms.region_name = tr.region_name
ORDER BY 
    ms.order_year, ms.order_month, ms.region_name;
