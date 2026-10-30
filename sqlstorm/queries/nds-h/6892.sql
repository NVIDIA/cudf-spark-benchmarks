WITH SupplierTotalCost AS (
    SELECT s_nationkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM supplier
    JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY s_nationkey
), RegionNation AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), RankedCost AS (
    SELECT rn.n_name, rn.r_name, stc.total_cost,
           RANK() OVER (PARTITION BY rn.r_name ORDER BY stc.total_cost DESC) AS cost_rank
    FROM SupplierTotalCost stc
    JOIN RegionNation rn ON stc.s_nationkey = rn.n_nationkey
)
SELECT r_name, n_name, total_cost
FROM RankedCost
WHERE cost_rank <= 5
ORDER BY r_name, total_cost DESC;
