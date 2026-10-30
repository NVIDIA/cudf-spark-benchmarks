WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as OrderRank
    FROM
        orders o
),
NationalAverage AS (
    SELECT
        n.n_name,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        n.n_name
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
            WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
            WHEN p.p_size > 20 THEN 'Large'
            ELSE 'Unknown'
        END AS SizeCategory
    FROM
        part p
),
CustOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS TotalSpent,
        COUNT(DISTINCT lo.l_orderkey) AS TotalOrders
    FROM
        customer c
    LEFT JOIN
        lineitem lo ON c.c_custkey = lo.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    r.o_orderkey,
    co.c_name,
    pd.p_name,
    pd.SizeCategory,
    NO.avg_acctbal,
    CASE 
        WHEN co.TotalSpent > NO.avg_acctbal THEN 'Above Average'
        ELSE 'Below Average'
    END AS SpendingComparison
FROM
    RankedOrders r
JOIN
    CustOrders co ON r.o_custkey = co.c_custkey
JOIN
    lineitem li ON r.o_orderkey = li.l_orderkey
JOIN
    PartDetails pd ON li.l_partkey = pd.p_partkey
JOIN
    NationalAverage NO ON (NO.avg_acctbal IS NOT NULL AND co.TotalSpent IS NOT NULL)
WHERE
    r.OrderRank = 1
    AND (co.TotalOrders > 5 OR co.TotalSpent IS NULL)
ORDER BY
    r.o_orderkey, SpendingComparison DESC
LIMIT 50;
