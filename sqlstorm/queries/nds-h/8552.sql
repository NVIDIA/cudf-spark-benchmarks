
WITH top_nations AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
    ORDER BY total_revenue DESC
    LIMIT 5
), part_details AS (
    SELECT p.p_name, p.p_brand, p.p_type, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name, p.p_brand, p.p_type
), revenue_summary AS (
    SELECT tn.n_name, pd.p_name, pd.p_brand, pd.p_type, SUM(o.o_totalprice) AS revenue
    FROM top_nations tn
    JOIN orders o ON o.o_orderstatus = 'F'
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN part_details pd ON p.p_name = pd.p_name
    GROUP BY tn.n_name, pd.p_name, pd.p_brand, pd.p_type
)
SELECT n.n_name, r.p_name, r.p_brand, r.p_type, r.revenue, pd.total_available
FROM revenue_summary r
JOIN part_details pd ON r.p_name = pd.p_name
JOIN top_nations n ON r.n_name = n.n_name
ORDER BY r.revenue DESC, pd.total_available DESC;
