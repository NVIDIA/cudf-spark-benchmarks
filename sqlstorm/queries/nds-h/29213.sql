WITH processed_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        CONCAT(r.r_name, ' - ', n.n_name) AS region_nation
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size > 10 AND l.l_shipmode LIKE 'AIR%'
    GROUP BY p.p_partkey, p.p_name, s.s_name, c.c_name, region_nation
)
SELECT 
    p_partkey,
    p_name,
    supplier_name,
    customer_name,
    order_count,
    ROUND(total_revenue, 2) AS total_revenue,
    region_nation
FROM processed_data
WHERE order_count > 0
ORDER BY total_revenue DESC
LIMIT 10;
