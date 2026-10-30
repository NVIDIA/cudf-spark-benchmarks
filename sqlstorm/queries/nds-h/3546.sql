WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY s.s_suppkey, s.s_name
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
RankedSales AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales,
        ss.order_count,
        ROW_NUMBER() OVER (PARTITION BY ss.s_suppkey ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SupplierSales ss
)

SELECT 
    cr.nation_name,
    cr.region_name,
    COALESCE(MAX(rs.total_sales), 0) AS max_supplier_sales,
    COALESCE(AVG(rs.total_sales), 0) AS avg_supplier_sales,
    COALESCE(SUM(CASE WHEN rs.order_count > 10 THEN 1 ELSE 0 END), 0) AS high_volume_suppliers
FROM CustomerRegions cr
LEFT JOIN RankedSales rs ON cr.c_custkey = rs.s_suppkey
WHERE rs.sales_rank <= 5 OR rs.sales_rank IS NULL
GROUP BY cr.nation_name, cr.region_name
ORDER BY cr.region_name, cr.nation_name;
