WITH RegionSales AS (
    SELECT r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY r.r_name
),
TopRegions AS (
    SELECT r_name, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionSales
)
SELECT r.r_name, r.total_sales
FROM TopRegions r
WHERE r.sales_rank <= 5
ORDER BY r.total_sales DESC;