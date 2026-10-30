WITH  RegionSales AS (
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY r.r_regionkey, r.r_name
    UNION ALL
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE r.r_regionkey IS NOT NULL
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, COALESCE(rs.total_sales, 0) AS total_region_sales,
       DENSE_RANK() OVER (ORDER BY COALESCE(rs.total_sales, 0) DESC) AS sales_rank
FROM region r
LEFT JOIN RegionSales rs ON r.r_regionkey = rs.r_regionkey
WHERE r.r_name NOT LIKE '%region%'
  AND (COALESCE(rs.total_sales, 0) > (SELECT AVG(total_sales) FROM RegionSales) OR rs.total_sales IS NULL)
ORDER BY total_region_sales DESC
LIMIT 10;
