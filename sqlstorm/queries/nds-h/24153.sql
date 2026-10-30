
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
), 
avg_supplier_cost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey
), 
top_part AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        AVG(l.l_quantity) AS avg_quantity
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE p.p_retailprice IS NOT NULL
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING AVG(l.l_quantity) > (SELECT AVG(subquery.avg_quantity) FROM (SELECT AVG(l2.l_quantity) AS avg_quantity FROM lineitem l2 GROUP BY l2.l_partkey) AS subquery)
), 
detailed_nation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
    HAVING COUNT(s.s_suppkey) > 5
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    p.p_name,
    s.s_name AS supplier_name,
    d.region_name,
    d.supplier_count,
    CASE 
        WHEN r.total_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Recorded'
    END AS revenue_status
FROM ranked_orders r
FULL OUTER JOIN detailed_nation d ON d.supplier_count = r.order_rank
LEFT JOIN top_part p ON p.p_partkey = r.o_orderkey
LEFT JOIN supplier s ON s.s_nationkey = d.n_nationkey
WHERE (r.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' OR r.o_orderdate IS NULL)
AND (p.p_retailprice < (SELECT MIN(ps_avg.avg_cost) FROM avg_supplier_cost ps_avg) OR s.s_name IS NULL)
ORDER BY r.total_revenue DESC, d.region_name, p.p_name;
