WITH SupplierPerformance AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT l.l_orderkey) AS TotalOrders,
        AVG(l.l_extendedprice) AS AvgLineItemPrice
    FROM
        supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
HighlyActiveSuppliers AS (
    SELECT
        sp.s_suppkey,
        sp.s_name,
        sp.TotalSupplyCost,
        sp.TotalOrders,
        sp.AvgLineItemPrice
    FROM
        SupplierPerformance sp
    WHERE
        sp.TotalOrders > (
            SELECT AVG(TotalOrders)
            FROM SupplierPerformance
        )
),
SupplierComments AS (
    SELECT
        s.s_suppkey,
        s.s_comment,
        rn.r_name
    FROM
        supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region rn ON n.n_regionkey = rn.r_regionkey
    WHERE
        s.s_comment NOT LIKE '%priority%' AND
        s.s_acctbal IS NOT NULL
)
SELECT
    ha.s_name,
    ha.TotalSupplyCost,
    ha.TotalOrders,
    ha.AvgLineItemPrice,
    COALESCE(sc.s_comment, 'No Comment Available') AS SupplierComment,
    ROW_NUMBER() OVER (PARTITION BY ha.s_suppkey ORDER BY ha.TotalSupplyCost DESC) AS SupplyRank
FROM
    HighlyActiveSuppliers ha
LEFT JOIN SupplierComments sc ON ha.s_suppkey = sc.s_suppkey
WHERE
    ha.TotalSupplyCost > 10000
ORDER BY
    ha.TotalSupplyCost DESC;
