WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
RegionSupplier AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
        JOIN region r ON n.n_regionkey = r.r_regionkey
        LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
), 
TotalSalesByRegion AS (
    SELECT 
        rs.r_regionkey,
        SUM(ss.total_sales) AS region_total_sales
    FROM 
        RegionSupplier rs
        LEFT JOIN SupplierSales ss ON rs.n_nationkey = ss.s_suppkey
    GROUP BY 
        rs.r_regionkey
)

SELECT 
    r.r_name,
    COALESCE(ts.region_total_sales, 0) AS total_sales,
    rs.supplier_count
FROM 
    region r
    LEFT JOIN TotalSalesByRegion ts ON r.r_regionkey = ts.r_regionkey
    LEFT JOIN RegionSupplier rs ON r.r_regionkey = rs.r_regionkey
WHERE 
    r.r_name LIKE 'S%'
ORDER BY 
    total_sales DESC, supplier_count ASC
LIMIT 5 OFFSET 10;
