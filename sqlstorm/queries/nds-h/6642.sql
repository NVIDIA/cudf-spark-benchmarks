WITH NationStats AS (
    SELECT n.n_nationkey, n.n_name, SUM(CASE 
        WHEN o.o_orderstatus = 'F' THEN 1 
        ELSE 0 END) AS finished_orders, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
    FROM nation n 
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey 
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey 
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey 
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31' 
    GROUP BY n.n_nationkey, n.n_name
), RankedNations AS (
    SELECT n.*, 
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank 
    FROM NationStats n
)
SELECT r.r_name AS region_name, rn.n_name AS nation_name, rn.finished_orders, rn.total_orders, rn.total_revenue 
FROM RankedNations rn 
JOIN nation n ON rn.n_nationkey = n.n_nationkey 
JOIN region r ON n.n_regionkey = r.r_regionkey 
WHERE rn.revenue_rank <= 5 
ORDER BY r.r_name, rn.total_revenue DESC;