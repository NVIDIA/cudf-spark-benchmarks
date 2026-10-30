
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS BalRank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 50000.00
)
SELECT 
    r.r_name AS RegionName,
    n.n_name AS NationName,
    p.p_name AS PartName,
    s.s_name AS SupplierName,
    pp.p_retailprice AS Price,
    cs.c_name AS CustomerName,
    o.o_orderkey AS OrderKey,
    COUNT(l.l_linenumber) AS LineItemCount
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer cs ON o.o_custkey = cs.c_custkey
JOIN 
    RankedParts pp ON p.p_partkey = pp.p_partkey
JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
WHERE 
    pp.BrandRank <= 5 AND
    ts.BalRank <= 10
GROUP BY 
    r.r_name, n.n_name, p.p_name, s.s_name, pp.p_retailprice, cs.c_name, o.o_orderkey
ORDER BY 
    r.r_name, n.n_name, s.s_name, pp.p_retailprice DESC;
