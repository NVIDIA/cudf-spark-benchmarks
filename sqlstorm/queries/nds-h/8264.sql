WITH nation_summary AS (
    SELECT n.n_name AS nation, SUM(o.o_totalprice) AS total_revenue, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY n.n_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(total_revenue) FROM (
        SELECT SUM(o.o_totalprice) AS total_revenue
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        GROUP BY o.o_orderkey
    ) AS average_revenue)
),
orders_per_nation AS (
    SELECT n.n_name AS nation, COUNT(o.o_orderkey) AS order_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
)
SELECT ns.nation, ns.total_revenue, ns.customer_count, opn.order_count
FROM nation_summary ns
JOIN orders_per_nation opn ON ns.nation = opn.nation
ORDER BY ns.total_revenue DESC, opn.order_count DESC;
