WITH  region_nation AS (
    SELECT r.r_regionkey, r.r_name AS region_name, n.n_nationkey, n.n_name AS nation_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
), aggregated_data AS (
    SELECT 
        pn.p_partkey,
        pn.p_name,
        SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        rn.region_name,
        rn.nation_name
    FROM part pn
    JOIN lineitem ls ON pn.p_partkey = ls.l_partkey
    JOIN orders o ON ls.l_orderkey = o.o_orderkey
    JOIN partsupp ps ON pn.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN region_nation rn ON s.s_nationkey = rn.n_nationkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY pn.p_partkey, pn.p_name, rn.region_name, rn.nation_name
)
SELECT region_name, nation_name, AVG(total_revenue) AS avg_revenue, MAX(order_count) AS max_orders
FROM aggregated_data
GROUP BY region_name, nation_name
HAVING AVG(total_revenue) > 10000
ORDER BY avg_revenue DESC, max_orders DESC;