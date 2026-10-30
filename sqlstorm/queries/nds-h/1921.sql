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
RegionSales AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(ss.total_sales) AS region_total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN SupplierSales ss ON n.n_nationkey = ss.s_suppkey
    GROUP BY n.n_regionkey, r.r_name
),
RankedRegionSales AS (
    SELECT 
        r.r_name,
        r.region_total_sales,
        RANK() OVER (ORDER BY r.region_total_sales DESC) AS sales_rank
    FROM RegionSales r
)
SELECT 
    p.p_name,
    COALESCE(rr.region_total_sales, 0) AS total_sales,
    rr.sales_rank,
    CASE 
        WHEN rr.region_total_sales IS NULL THEN 'No Sales'
        ELSE 'Active Sales'
    END AS sales_status
FROM part p
LEFT JOIN RankedRegionSales rr ON p.p_name = CONCAT('%', rr.r_name, '%')
WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
AND p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 50.00)
ORDER BY rr.sales_rank, total_sales DESC;
