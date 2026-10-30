
WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, c.c_name, c.c_nationkey
),
TopSales AS (
    SELECT 
        c.c_nationkey,
        SUM(s.total_sales) AS nation_total_sales,
        COUNT(DISTINCT s.o_orderkey) AS order_count
    FROM SalesCTE s
    JOIN customer c ON s.c_name = c.c_name
    WHERE s.sales_rank <= 10
    GROUP BY c.c_nationkey
),
RegionSummary AS (
    SELECT 
        r.r_name,
        COALESCE(SUM(ts.nation_total_sales), 0) AS total_sales,
        COALESCE(SUM(ts.order_count), 0) AS total_orders
    FROM region r
    LEFT JOIN TopSales ts ON r.r_regionkey = ts.c_nationkey
    GROUP BY r.r_name
)
SELECT 
    r.r_name,
    r.total_sales,
    r.total_orders,
    CASE 
        WHEN r.total_sales > 1000000 THEN 'High Sales'
        WHEN r.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM RegionSummary r
WHERE r.total_orders > (
    SELECT AVG(R.total_orders)
    FROM RegionSummary R
    WHERE R.total_orders IS NOT NULL
)
ORDER BY r.total_sales DESC;
