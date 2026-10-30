WITH  price_calculation AS (
    SELECT p.p_partkey, 
           p.p_name,
           ps.ps_supplycost,
           ps.ps_availqty,
           (ps.ps_supplycost * ps.ps_availqty) AS total_value,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY (ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
), filtered_parts AS (
    SELECT p_partkey, 
           p_name,
           SUM(total_value) AS total_cost
    FROM price_calculation
    WHERE rank = 1
    GROUP BY p_partkey, p_name
), supplier_info AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_comment,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_comment
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
), order_summary AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderstatus
), final_output AS (
    SELECT f.p_name, 
           f.total_cost,
           s.s_name AS supplier_name,
           os.total_revenue,
           CASE WHEN os.total_revenue IS NULL THEN 'No Revenue' ELSE 'Has Revenue' END AS revenue_status
    FROM filtered_parts f
    LEFT JOIN supplier_info s ON f.p_partkey = s.s_suppkey
    FULL OUTER JOIN order_summary os ON s.s_suppkey = os.o_orderkey
    WHERE f.total_cost > (SELECT AVG(total_cost) FROM filtered_parts) 
      OR os.total_revenue IS NULL
)
SELECT * FROM final_output
WHERE total_cost > 1000
ORDER BY total_cost DESC;
