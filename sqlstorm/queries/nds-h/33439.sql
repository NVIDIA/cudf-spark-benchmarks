WITH  regional_sales AS (
    SELECT n.n_nationkey, r.r_regionkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_nationkey, r.r_regionkey
    UNION ALL
    SELECT n.n_nationkey, r.r_regionkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l_shipdate >= (SELECT MAX(l_shipdate) FROM lineitem) - INTERVAL '1 year'
    GROUP BY n.n_nationkey, r.r_regionkey
), customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
), ranked_customers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent,
           RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM customer_summary c
)
SELECT r.r_regionkey,
       COUNT(DISTINCT rc.c_custkey) AS active_customers,
       SUM(rs.total_sales) AS total_region_sales,
       AVG(rc.total_spent) AS average_customer_spent
FROM regional_sales rs
JOIN ranked_customers rc ON rs.n_nationkey = rc.c_custkey
RIGHT JOIN region r ON rs.r_regionkey = r.r_regionkey
WHERE rs.total_sales IS NOT NULL
GROUP BY r.r_regionkey
ORDER BY r.r_regionkey;
