WITH NationOrders AS (
    SELECT n.n_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_value
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
),
RegionSummary AS (
    SELECT r.r_name, SUM(no.order_count) AS total_orders, SUM(no.total_value) AS total_value
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationOrders no ON n.n_name = no.n_name
    GROUP BY r.r_name
)
SELECT r.r_name, rs.total_orders, rs.total_value,
       CASE 
           WHEN rs.total_value > 1000000 THEN 'High Value'
           WHEN rs.total_value BETWEEN 500000 AND 1000000 THEN 'Medium Value'
           ELSE 'Low Value' 
       END AS value_category
FROM RegionSummary rs
JOIN region r ON rs.r_name = r.r_name
ORDER BY rs.total_value DESC, rs.total_orders DESC;
