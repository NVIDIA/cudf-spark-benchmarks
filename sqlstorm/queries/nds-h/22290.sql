WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderstatus IN ('F', 'O')
    GROUP BY r.r_name
),
TopRegions AS (
    SELECT 
        region_name, 
        total_sales, 
        rank() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionalSales
),
FilteredRegions AS (
    SELECT * 
    FROM TopRegions 
    WHERE sales_rank <= 3
)
SELECT 
    fr.region_name,
    fr.total_sales,
    (SELECT COUNT(*) FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_size > 10))) AS loyal_customers_count,
    COALESCE((SELECT AVG(c.c_acctbal) FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey)), 0) AS avg_account_balance,
    CASE 
        WHEN fr.total_sales > 100000 THEN 'High Performer'
        WHEN fr.total_sales BETWEEN 50000 AND 100000 THEN 'Moderate Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM FilteredRegions fr
ORDER BY fr.total_sales DESC;
