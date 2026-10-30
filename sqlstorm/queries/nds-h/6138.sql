WITH RegionSales AS (
    SELECT r.r_name AS region_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
),
AvgSales AS (
    SELECT AVG(total_sales) AS avg_sales
    FROM RegionSales
),
HighSalesRegions AS (
    SELECT region_name, total_sales
    FROM RegionSales
    WHERE total_sales > (SELECT avg_sales FROM AvgSales)
)
SELECT region_name, total_sales
FROM HighSalesRegions
ORDER BY total_sales DESC
LIMIT 10;
