WITH RegionSales AS (
    SELECT r_name, SUM(o_totalprice) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r_name
), HighSales AS (
    SELECT r_name, total_sales
    FROM RegionSales
    WHERE total_sales > (SELECT AVG(total_sales) FROM RegionSales)
)
SELECT r_name, total_sales, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM HighSales
ORDER BY sales_rank
LIMIT 10;
