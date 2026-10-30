WITH nation_orders AS (
    SELECT n.n_nationkey, n.n_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
), ranked_nations AS (
    SELECT n_nationkey, n_name, order_count, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM nation_orders
)
SELECT r.r_name AS region_name, rn.n_name as nation_name, rn.order_count, rn.total_sales
FROM ranked_nations rn
JOIN nation n ON rn.n_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rn.sales_rank <= 5
ORDER BY r.r_name, rn.total_sales DESC;
