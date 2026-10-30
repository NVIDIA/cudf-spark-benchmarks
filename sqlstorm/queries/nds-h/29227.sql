WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 25
),
NationData AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.ps_partkey,
        sp.ps_availqty,
        sp.ps_supplycost,
        (sp.ps_supplycost * sp.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp sp ON s.s_suppkey = sp.ps_suppkey
    WHERE s.s_acctbal > 50000
),
FinalBenchmark AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        SUM(sp.TotalCost) AS TotalSupplierCost,
        COUNT(DISTINCT sp.s_suppkey) AS SupplierCount,
        AVG(sp.ps_supplycost) AS AvgSupplyCost
    FROM RankedParts rp
    JOIN SupplierPartInfo sp ON rp.p_partkey = sp.ps_partkey
    JOIN NationData nd ON sp.s_suppkey = nd.n_nationkey
    GROUP BY rp.p_name, rp.p_brand
)
SELECT 
    fb.p_name,
    fb.p_brand,
    fb.TotalSupplierCost,
    fb.SupplierCount,
    fb.AvgSupplyCost
FROM FinalBenchmark fb
WHERE fb.SupplierCount > 5
ORDER BY fb.TotalSupplierCost DESC
LIMIT 10;
