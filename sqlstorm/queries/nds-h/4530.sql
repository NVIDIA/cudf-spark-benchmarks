WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
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
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        region,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
TopRegions AS (
    SELECT 
        region, total_sales, order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)

SELECT 
    tr.region,
    tr.total_sales,
    tr.order_count,
    COALESCE(ROUND(tr.total_sales / NULLIF(SUM(tr.total_sales) OVER (), 0) * 100, 2), 0) AS sales_percentage,
    CASE 
        WHEN tr.order_count > 100 THEN 'High Volume'
        WHEN tr.order_count BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    TopRegions tr
LEFT JOIN 
    (SELECT
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1998-01-01') total
ON 1=1
ORDER BY 
    tr.total_sales DESC;