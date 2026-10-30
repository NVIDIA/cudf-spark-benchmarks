WITH  national_sales AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_name
),
region_summary AS (
    SELECT 
        r.r_name,
        COALESCE(SUM(ns.total_sales), 0) AS total_region_sales,
        COUNT(ns.n_name) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN national_sales ns ON n.n_name = ns.n_name
    GROUP BY r.r_name
),
sales_analysis AS (
    SELECT 
        r.r_name,
        r.total_region_sales,
        r.nation_count,
        ROUND((r.total_region_sales / NULLIF(r.nation_count, 0)), 2) AS avg_sales_per_nation
    FROM region_summary r
)
SELECT 
    ra.r_name,
    ra.total_region_sales,
    ra.avg_sales_per_nation,
    CASE 
        WHEN ra.avg_sales_per_nation > 10000 THEN 'High Sales' 
        WHEN ra.avg_sales_per_nation BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales' 
    END AS sales_category,
    (
        SELECT COUNT(*)
        FROM orders o
        WHERE o.o_orderdate < cast('1998-10-01' as date) - INTERVAL '1 YEAR'
        AND EXISTS (
            SELECT 1 
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey 
            AND l.l_returnflag = 'R'
        )
    ) AS old_returned_orders_count
FROM sales_analysis ra
WHERE EXISTS (
    SELECT 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty < (SELECT AVG(ps_inner.ps_availqty) FROM partsupp ps_inner)
    AND s.s_acctbal IS NOT NULL
)
ORDER BY ra.total_region_sales DESC, ra.r_name ASC
LIMIT 10;