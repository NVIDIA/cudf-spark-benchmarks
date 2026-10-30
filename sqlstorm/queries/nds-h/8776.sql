WITH supplier_info AS (
    SELECT s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
active_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1997-01-01'
),
line_item_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT si.nation_name, COUNT(DISTINCT ao.o_orderkey) AS active_order_count, 
       SUM(lis.total_revenue) AS total_revenue, 
       AVG(si.s_acctbal) AS avg_supplier_acctbal
FROM supplier_info si
JOIN partsupp ps ON si.s_name = ps.ps_comment
JOIN line_item_summary lis ON ps.ps_partkey = lis.l_orderkey
JOIN active_orders ao ON lis.l_orderkey = ao.o_orderkey
GROUP BY si.nation_name
ORDER BY total_revenue DESC, active_order_count DESC;