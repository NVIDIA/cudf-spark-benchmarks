WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
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
    GROUP BY
        r.r_name
),
FilteredSales AS (
    SELECT
        region_name,
        total_sales,
        num_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
)
SELECT
    fs.region_name,
    fs.total_sales,
    fs.num_orders,
    COALESCE(ROUND(avg_price), 0) AS avg_order_price,
    CASE 
        WHEN fs.num_orders = 0 THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status
FROM
    FilteredSales fs
LEFT JOIN (
    SELECT 
        r.r_name,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
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
    GROUP BY 
        r.r_name
) AS AvgSales ON fs.region_name = AvgSales.r_name
WHERE
    fs.sales_rank <= 5
ORDER BY
    fs.total_sales DESC;
