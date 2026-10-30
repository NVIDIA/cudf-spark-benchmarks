WITH RankedPart AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rn
    FROM
        part p
    WHERE
        p.p_retailprice IS NOT NULL
        AND p.p_size BETWEEN 1 AND 15
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name,
        s.s_acctbal,
        COALESCE(s.s_comment, 'No Comment') AS SupplierComment
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
),
AggregateOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT l.l_orderkey) AS LineItemsCount
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'O' 
        AND l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY
        o.o_orderkey, o.o_orderdate
)
SELECT
    COALESCE(rp.p_name, 'Unknown Part') AS PartName,
    si.s_name AS SupplierName,
    ao.o_orderkey AS OrderKey,
    ao.TotalSales,
    RANK() OVER (PARTITION BY rp.p_partkey ORDER BY ao.TotalSales DESC) AS SalesRank,
    CASE
        WHEN ao.TotalSales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS SalesStatus
FROM
    RankedPart rp
FULL OUTER JOIN
    SupplierInfo si ON rp.p_partkey = si.s_suppkey
LEFT JOIN
    AggregateOrders ao ON si.s_suppkey = ao.o_orderkey
WHERE
    (rp.rn = 1 OR ao.LineItemsCount > 0) 
    AND (rp.p_retailprice IS NOT NULL OR si.s_acctbal IS NULL)
ORDER BY
    PartName, SupplierName DESC, TotalSales DESC;