WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationTotalCost AS (
    SELECT n.n_nationkey, SUM(sd.TotalCost) AS NationTotalCost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    GROUP BY n.n_nationkey
),
FinalCostReport AS (
    SELECT n.n_name, ntc.NationTotalCost, (SELECT SUM(NationTotalCost) FROM NationTotalCost) AS GlobalTotalCost
    FROM nation n
    JOIN NationTotalCost ntc ON n.n_nationkey = ntc.n_nationkey
)
SELECT f.n_name, f.NationTotalCost, (f.NationTotalCost / f.GlobalTotalCost * 100) AS PercentageOfGlobalCost
FROM FinalCostReport f
ORDER BY f.NationTotalCost DESC
LIMIT 10;
