
WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM
        part p
    WHERE
        p.p_size BETWEEN 1 AND 10
), SupplierInRegion AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name
    FROM
        supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        n.n_regionkey IS NOT NULL
), Popularity AS (
    SELECT
        l.l_partkey,
        SUM(l.l_quantity) AS total_qty
    FROM
        lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderstatus = 'O' AND
        l.l_shipdate >= '1997-01-01' AND
        l.l_shipdate < '1998-01-01'
    GROUP BY
        l.l_partkey
), TopSamples AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        COALESCE(pu.total_qty, 0) AS total_ordered,
        CASE WHEN pu.total_qty IS NULL THEN 'Not ordered' ELSE 'Ordered' END AS order_status
    FROM
        RankedParts p
    LEFT JOIN Popularity pu ON p.p_partkey = pu.l_partkey
    WHERE
        (p.p_brand LIKE 'A%' OR p.p_brand LIKE 'B%')
        AND p.rn <= 5
)
SELECT
    ts.p_partkey,
    ts.p_name,
    ts.p_mfgr,
    ts.total_ordered,
    ts.order_status,
    CASE
        WHEN ts.total_ordered > 100 THEN 'High Demand'
        WHEN ts.total_ordered BETWEEN 50 AND 100 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category,
    s.s_name, 
    s.s_acctbal
FROM
    TopSamples ts
LEFT JOIN SupplierInRegion s ON ts.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty > 20 AND ps.ps_supplycost < 100
) 
WHERE
    ts.total_ordered IS NOT NULL
ORDER BY
    demand_category DESC,
    total_ordered DESC,
    ts.p_partkey;
