WITH NationalSales AS (
    SELECT n.n_name AS nation,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_name
),
RankedSales AS (
    SELECT nation,
           total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM NationalSales
)
SELECT r.r_name AS region,
       rs.nation,
       rs.total_sales
FROM RankedSales rs
JOIN nation n ON rs.nation = n.n_name
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rs.sales_rank <= 5
ORDER BY r.r_name, rs.total_sales DESC;
