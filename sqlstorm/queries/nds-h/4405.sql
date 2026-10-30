
WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey, 
        sp.s_name,
        sp.total_avail_qty,
        sp.total_sales,
        sp.total_orders,
        sp.sales_rank
    FROM SupplierPerformance sp
    WHERE sp.sales_rank <= 5
),
SalesByRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        SUM(sp.total_sales) AS region_sales
    FROM TopSuppliers sp
    JOIN supplier s ON sp.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_name
)
SELECT 
    r.r_name,
    COALESCE(s.region_sales, 0) AS total_sales,
    COALESCE((SELECT AVG(sp.total_orders) FROM TopSuppliers sp WHERE sp.total_orders IS NOT NULL), 0) AS avg_orders
FROM region r
LEFT JOIN SalesByRegion s ON r.r_name = s.r_name
WHERE r.r_name IS NOT NULL 
ORDER BY total_sales DESC, r.r_name;
