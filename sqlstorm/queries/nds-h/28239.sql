
WITH supplier_details AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_address,
           s.s_nationkey,
           n.n_name AS nation_name,
           n.n_comment AS nation_comment,
           COUNT(ps.ps_partkey) AS total_parts,
           SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, n.n_name, n.n_comment
),
order_summary AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS total_lineitems,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
benchmark_result AS (
    SELECT sd.s_name,
           sd.nation_name,
           os.o_orderkey,
           os.total_revenue,
           os.total_lineitems,
           (sd.total_supply_cost / NULLIF(os.total_lineitems, 0)) AS avg_supply_cost_per_lineitem
    FROM supplier_details sd
    LEFT JOIN order_summary os ON sd.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey
            FROM lineitem l
            WHERE l.l_returnflag = 'R'
        )
    )
)
SELECT s_name,
       nation_name,
       SUM(total_revenue) AS aggregated_revenue,
       AVG(avg_supply_cost_per_lineitem) AS avg_cost_per_lineitem
FROM benchmark_result
GROUP BY s_name, nation_name
ORDER BY aggregated_revenue DESC;
