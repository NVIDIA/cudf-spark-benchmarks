
WITH part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(REPLACE(p.p_name, ' ', '_'), '_', LPAD(CAST(p.p_partkey AS STRING), 10, '0')) AS part_identifier,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        ARRAY_AGG(DISTINCT s.s_name) AS suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
),
nation_avg AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        AVG(c.c_acctbal) AS avg_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN customer c ON s.s_suppkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ps.part_identifier,
    ps.p_name,
    ps.p_brand,
    na.n_name,
    na.avg_acctbal,
    na.total_orders,
    CASE
        WHEN na.total_orders > 100 THEN 'High Activity'
        WHEN na.total_orders BETWEEN 50 AND 100 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM part_summary ps
JOIN nation_avg na ON MOD(ps.p_partkey, 5) = na.n_nationkey
WHERE ps.avg_supplycost < (SELECT AVG(ps_avg.avg_supplycost) FROM part_summary ps_avg)
ORDER BY na.total_orders DESC, ps.p_name;
