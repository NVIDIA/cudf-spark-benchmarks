WITH RegionStats AS (
    SELECT r.r_name AS region_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY r.r_name
),
AverageOrderValue AS (
    SELECT AVG(total_sales) AS avg_order_value
    FROM RegionStats
),
TopRegions AS (
    SELECT region_name, total_sales
    FROM RegionStats
    WHERE total_sales > (SELECT avg_order_value FROM AverageOrderValue)
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT tr.region_name, 
       tr.total_sales, 
       r.r_comment
FROM TopRegions tr
JOIN region r ON tr.region_name = r.r_name
ORDER BY tr.total_sales DESC;