
WITH nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 1000
),
part_line_item AS (
    SELECT p.p_partkey, p.p_name, l.l_orderkey, l.l_quantity, l.l_extendedprice
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
),
aggregated_data AS (
    SELECT ns.n_name, pl.p_name, SUM(pl.l_extendedprice) AS total_revenue, COUNT(DISTINCT pl.l_orderkey) AS order_count
    FROM nation_supplier ns
    JOIN part_line_item pl ON ns.s_suppkey = pl.l_orderkey
    GROUP BY ns.n_name, pl.p_name
)
SELECT ad.n_name, ad.p_name, ad.total_revenue, ad.order_count
FROM aggregated_data ad
WHERE ad.total_revenue > (
    SELECT AVG(total_revenue) FROM aggregated_data
)
ORDER BY ad.total_revenue DESC
LIMIT 10;
