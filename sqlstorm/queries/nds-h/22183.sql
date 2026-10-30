
WITH  RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(n.n_nationkey) > (
        SELECT AVG(nation_count)
        FROM (
            SELECT COUNT(n_nationkey) AS nation_count
            FROM nation
            GROUP BY n_regionkey
        ) AS avg_nations
    )
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighCostParts AS (
    SELECT p.p_partkey, p.p_name
    FROM part p
    JOIN PartSupplierInfo psi ON p.p_partkey = psi.ps_partkey
    WHERE psi.avg_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp)
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' 
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT rs.r_name,
       COALESCE(ROUND(AVG(odi.total_revenue), 2), 0) AS avg_revenue,
       COALESCE(SUM(CASE WHEN odi.o_orderstatus = 'F' THEN 1 ELSE 0 END), 0) AS fulfilled_orders,
       STRING_AGG(DISTINCT hcp.p_name, '; ') AS high_cost_parts
FROM RegionSummary rs
LEFT JOIN OrderDetails odi ON rs.nation_count > (SELECT AVG(nation_count) FROM RegionSummary)
LEFT JOIN HighCostParts hcp ON rs.r_regionkey IN (
    SELECT DISTINCT n.n_regionkey 
    FROM nation n 
    WHERE n.n_nationkey IN (
        SELECT s.s_nationkey 
        FROM supplier s 
        WHERE s.s_acctbal > 50000
    )
)
GROUP BY rs.r_name
ORDER BY rs.r_name, avg_revenue DESC NULLS LAST;
