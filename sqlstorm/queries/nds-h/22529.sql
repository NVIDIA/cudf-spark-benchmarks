WITH RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supply_accounts
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           PERCENT_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
PartSupplierStats AS (
    SELECT ps.ps_partkey,
           COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_availability_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
BizarreAggregates AS (
    SELECT COALESCE(NULLIF(MAX(ps.total_availability_cost), 0), SUM(cli.l_quantity)) AS bizarre_total
    FROM PartSupplierStats ps
    JOIN lineitem cli ON ps.ps_partkey = cli.l_partkey
    WHERE cli.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
),
SelectedRegions AS (
    SELECT r.r_name, rs.nation_count, rs.total_supply_accounts
    FROM RegionStats rs
    JOIN region r ON rs.r_name = r.r_name
    WHERE rs.nation_count > (SELECT AVG(nation_count) FROM RegionStats)
)
SELECT cr.total_spent, sr.r_name,
       CASE 
           WHEN cr.total_spent IS NULL THEN 'No Orders' 
           WHEN cr.spend_rank <= 0.5 THEN 'Moderate Spender' 
           ELSE 'Top Spender' 
       END AS spend_category,
       b.bizarre_total
FROM CustomerOrders cr
CROSS JOIN BizarreAggregates b
JOIN SelectedRegions sr ON sr.total_supply_accounts > b.bizarre_total
WHERE sr.nation_count IS NOT NULL
ORDER BY cr.total_spent DESC NULLS LAST
LIMIT 100;