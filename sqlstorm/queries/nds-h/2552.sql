WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
OverallStats AS (
    SELECT 
        SUM(total_sales) AS overall_sales,
        AVG(order_count) AS average_order_count
    FROM 
        TopRegions
)
SELECT 
    tr.region,
    tr.total_sales,
    tr.order_count,
    os.overall_sales,
    os.average_order_count,
    CASE WHEN tr.total_sales > os.average_order_count THEN 'Above Average' ELSE 'Below Average' END AS sales_performance
FROM 
    TopRegions tr
CROSS JOIN 
    OverallStats os
WHERE 
    tr.sales_rank <= 5
ORDER BY 
    tr.total_sales DESC;