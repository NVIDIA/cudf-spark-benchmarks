
WITH  nation_sales AS (
    SELECT n.n_nationkey, n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
        SELECT AVG(total_sales)
        FROM (
            SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_sales
            FROM lineitem l
            JOIN orders o ON l.l_orderkey = o.o_orderkey
            GROUP BY o.o_custkey
        ) AS avg_sales
    )
),
ranked_sales AS (
    SELECT n.n_name, ns.total_sales, 
           RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM nation_sales ns
    JOIN nation n ON ns.n_nationkey = n.n_nationkey
)
SELECT r.sales_rank, r.n_name, r.total_sales
FROM ranked_sales r
WHERE r.sales_rank <= 5
ORDER BY r.sales_rank;
