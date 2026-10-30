WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS SizeCategory,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
Combined AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.SizeCategory,
        si.s_name,
        si.nation_name,
        si.region_name,
        si.s_acctbal
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
    WHERE 
        rp.BrandRank <= 3
)
SELECT 
    c.p_partkey,
    c.p_name,
    c.SizeCategory,
    SUM(c.s_acctbal) AS TotalSupplierAccountBalance,
    COUNT(c.s_name) AS SupplierCount
FROM 
    Combined c
GROUP BY 
    c.p_partkey, c.p_name, c.SizeCategory
ORDER BY 
    TotalSupplierAccountBalance DESC, SupplierCount DESC;
