WITH ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS brand_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
      AND l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY p.p_partkey, p.p_name, p.p_brand
), top_parts AS (
    SELECT p.*, brand_rank
    FROM ranked_parts p
    WHERE brand_rank <= 10
)
SELECT tp.p_brand, SUM(tp.revenue) AS total_revenue
FROM top_parts tp
GROUP BY tp.p_brand
ORDER BY total_revenue DESC;