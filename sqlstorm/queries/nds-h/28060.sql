WITH PartInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment,
        CONCAT(p.p_name, ' (', p.p_brand, ') - ', p.p_type) AS FullDescription 
    FROM 
        part p 
    WHERE 
        p.p_size > 10
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_phone, 
        s.s_acctbal,
        s.s_comment,
        REPLACE(s.s_name, 'Supply', 'Supplier') AS AdjustedName
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal > 1000
),
CustomerInfo AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_address, 
        c.c_phone, 
        LENGTH(c.c_comment) AS CommentLength,
        CONCAT(c.c_name, ' - ', c.c_mktsegment) AS CustomerDetails 
    FROM 
        customer c 
    WHERE 
        c.c_mktsegment = 'BUILDING'
)
SELECT 
    pi.FullDescription, 
    si.AdjustedName, 
    ci.CustomerDetails,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
FROM 
    PartInfo pi 
JOIN 
    partsupp ps ON pi.p_partkey = ps.ps_partkey 
JOIN 
    supplierinfo si ON ps.ps_suppkey = si.s_suppkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    CustomerInfo ci ON o.o_custkey = ci.c_custkey 
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1997-12-31' 
GROUP BY 
    pi.FullDescription, si.AdjustedName, ci.CustomerDetails
ORDER BY 
    TotalRevenue DESC 
LIMIT 10;