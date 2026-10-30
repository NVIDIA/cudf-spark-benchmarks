
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_retailprice, 
        SUBSTRING(p.p_comment, 1, 10) AS short_comment, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS rank 
    FROM 
        part p 
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), SelectedParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.short_comment, 
        rp.p_retailprice 
    FROM 
        RankedParts rp 
    WHERE 
        rp.rank <= 5
), RegionSupplier AS (
    SELECT 
        r.r_name, 
        s.s_name, 
        s.s_acctbal 
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey 
    WHERE 
        s.s_acctbal > 50000.00
)
SELECT 
    sp.p_name, 
    sp.short_comment, 
    sp.p_retailprice, 
    rs.r_name, 
    rs.s_name, 
    rs.s_acctbal 
FROM 
    SelectedParts sp 
JOIN 
    RegionSupplier rs ON LENGTH(sp.p_name) = LENGTH(rs.s_name)
ORDER BY 
    sp.p_retailprice DESC, rs.s_acctbal ASC;
