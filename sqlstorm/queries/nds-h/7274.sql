WITH top_nations AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY n.n_name
    ORDER BY total_revenue DESC
    LIMIT 5
),
supplier_details AS (
    SELECT s.s_name, s.s_address, s.s_phone, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN (SELECT n_name FROM top_nations)
),
part_statistics AS (
    SELECT p.p_name, SUM(l.l_quantity) AS total_quantity, AVG(l.l_extendedprice) AS avg_price
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_name
    ORDER BY total_quantity DESC
    LIMIT 10
)
SELECT tn.n_name AS nation_name, sd.s_name AS supplier_name, sd.s_address, sd.s_phone, sd.s_acctbal,
       ps.p_name AS part_name, ps.total_quantity, ps.avg_price
FROM top_nations tn
JOIN supplier_details sd ON tn.n_name = sd.s_name
JOIN part_statistics ps ON ps.total_quantity > 1000
ORDER BY tn.total_revenue DESC, ps.total_quantity DESC;