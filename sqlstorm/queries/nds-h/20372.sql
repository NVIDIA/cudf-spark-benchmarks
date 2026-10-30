WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as BrandRank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CASE 
            WHEN l.l_returnflag = 'Y' THEN 'Returned'
            ELSE 'Not Returned'
        END AS ReturnStatus,
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS LineRank
    FROM 
        lineitem l
    WHERE 
        l.l_discount BETWEEN 0.1 AND 0.5
    AND 
        l.l_tax IS NOT NULL
)
SELECT 
    c.c_name,
    o.o_orderkey,
    SUM(f.l_extendedprice * (1 - f.l_discount)) AS TotalRevenue,
    SUM(CASE 
            WHEN f.l_discount > 0.3 THEN f.l_tax 
            ELSE NULL 
        END) AS TaxOnDiscountedItems,
    COUNT(DISTINCT fp.p_partkey) AS DistinctHighValBrandParts,
    ns.n_name AS SupplierNation
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    FilteredLineItems f ON o.o_orderkey = f.l_orderkey
LEFT JOIN 
    RankedParts fp ON f.l_partkey = fp.p_partkey AND fp.BrandRank <= 5
JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN 
    HighValueSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
LEFT JOIN 
    nation ns ON hvs.s_nationkey = ns.n_nationkey
WHERE 
    o.o_orderstatus IN ('F', 'O')
AND 
    (c.c_acctbal IS NULL OR c.c_acctbal > 500)
GROUP BY 
    c.c_name, o.o_orderkey, ns.n_name
HAVING 
    SUM(f.l_extendedprice * (1 - f.l_discount)) > 10000
ORDER BY 
    TotalRevenue DESC, c.c_name;
