WITH NationSummary AS (
    SELECT n.n_name AS nation_name, 
           SUM(o.o_totalprice) AS total_revenue, 
           COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY n.n_name
),
TopNations AS (
    SELECT nation_name, 
           total_revenue, 
           customer_count,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM NationSummary
)
SELECT tn.nation_name, 
       tn.total_revenue, 
       tn.customer_count
FROM TopNations tn
WHERE tn.revenue_rank <= 5
ORDER BY tn.total_revenue DESC;
