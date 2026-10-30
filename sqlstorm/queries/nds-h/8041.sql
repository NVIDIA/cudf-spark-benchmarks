WITH  nation_summary AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(o.o_totalprice) > 10000
), ranked_nations AS (
    SELECT n.n_name, n.total_sales, ROW_NUMBER() OVER (ORDER BY n.total_sales DESC) as rank
    FROM nation_summary n
)
SELECT rn.rank, rn.n_name, rn.total_sales, 
       CASE 
           WHEN rn.rank <= 5 THEN 'Top Nation'
           ELSE 'Other Nation'
       END AS classification
FROM ranked_nations rn
ORDER BY rn.rank;
