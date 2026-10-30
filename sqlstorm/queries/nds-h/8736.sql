WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationPerformance AS (
    SELECT n.n_nationkey, n.n_name, SUM(sd.TotalSupplyCost) AS TotalNationSupplyCost
    FROM nation n
    JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
BestPerformingNation AS (
    SELECT n.n_name, np.TotalNationSupplyCost,
           RANK() OVER (ORDER BY np.TotalNationSupplyCost DESC) AS Rank
    FROM nation n
    JOIN NationPerformance np ON n.n_nationkey = np.n_nationkey
)
SELECT bp.n_name AS BestNation, bp.TotalNationSupplyCost
FROM BestPerformingNation bp
WHERE bp.Rank = 1;
