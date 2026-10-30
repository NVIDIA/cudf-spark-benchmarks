WITH part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * p.p_retailprice) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
region_nation AS (
    SELECT n.n_nationkey, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT r.r_name, SUM(ps.total_cost) AS total_revenue
FROM part_supplier ps
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN partsupp psup ON ps.ps_partkey = psup.ps_partkey
JOIN supplier s ON psup.ps_suppkey = s.s_suppkey
JOIN region_nation rn ON s.s_nationkey = rn.n_nationkey
JOIN region r ON rn.r_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;
