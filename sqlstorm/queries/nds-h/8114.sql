WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, p.p_name AS top_part
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, p.p_name
    ORDER BY SUM(ps.ps_supplycost) DESC
    LIMIT 5
), OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice
), FinalStats AS (
    SELECT sd.s_name, sd.nation_name, os.revenue, os.o_totalprice
    FROM SupplierDetails sd
    JOIN OrderStats os ON sd.top_part IN (
        SELECT p_name
        FROM part
        WHERE p_size > 10
        ORDER BY p_retailprice DESC
        LIMIT 3
    )
)
SELECT s_name, nation_name, AVG(revenue) AS avg_revenue, AVG(o_totalprice) AS avg_order_total
FROM FinalStats
GROUP BY s_name, nation_name
ORDER BY avg_revenue DESC;