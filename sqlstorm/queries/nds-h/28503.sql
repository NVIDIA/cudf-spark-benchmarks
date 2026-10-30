WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
AggregateOrderData AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_linenumber) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    fs.s_name,
    fs.s_acctbal,
    aod.total_line_items,
    aod.total_sales
FROM RankedParts rp
JOIN FilteredSuppliers fs ON rp.p_partkey = fs.s_nationkey 
JOIN AggregateOrderData aod ON fs.s_suppkey = aod.o_orderkey
WHERE rp.rn <= 5
ORDER BY rp.p_brand, aod.total_sales DESC;
