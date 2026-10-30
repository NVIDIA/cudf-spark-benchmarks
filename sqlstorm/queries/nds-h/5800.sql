WITH filtered_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
      AND o.o_orderstatus = 'F'
), enriched_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_shipdate,
           p.p_brand, p.p_type, s.s_nationkey
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), revenue_by_nation AS (
    SELECT n.n_name AS nation_name, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM enriched_lineitems li
    JOIN nation n ON li.s_nationkey = n.n_nationkey
    JOIN filtered_orders fo ON li.l_orderkey = fo.o_orderkey
    GROUP BY n.n_name
)
SELECT nation_name, total_revenue
FROM revenue_by_nation
ORDER BY total_revenue DESC
LIMIT 10;
