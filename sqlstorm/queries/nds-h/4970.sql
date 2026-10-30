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
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        region_name,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        total_orders
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    t.region_name,
    t.total_sales,
    t.total_orders,
    COALESCE((SELECT AVG(total_sales) FROM TopRegions), 0) AS avg_top_sales,
    (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey IN 
        (SELECT DISTINCT l.l_orderkey 
         FROM lineitem l 
         JOIN part p ON l.l_partkey = p.p_partkey 
         WHERE p.p_size BETWEEN 10 AND 20)) AS related_orders_count
FROM 
    TopRegions t
ORDER BY 
    t.total_sales DESC;
