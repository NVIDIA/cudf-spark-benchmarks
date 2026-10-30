WITH NationSales AS (
    SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_name
), RegionSales AS (
    SELECT r.r_name, SUM(ns.total_sales) AS region_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationSales ns ON n.n_name = ns.n_name
    GROUP BY r.r_name
), RankedSales AS (
    SELECT r.r_name, r.region_sales, RANK() OVER (ORDER BY r.region_sales DESC) AS sales_rank
    FROM RegionSales r
)
SELECT r.r_name, r.region_sales
FROM RankedSales r
WHERE r.sales_rank <= 5
ORDER BY r.region_sales DESC;
