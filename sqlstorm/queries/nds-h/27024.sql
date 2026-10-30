
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment
    FROM 
        RankedParts p
    WHERE 
        rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_address, 
        s.s_phone, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CombinedDetails AS (
    SELECT 
        fp.p_name,
        fp.p_brand,
        fp.p_retailprice,
        sd.s_name,
        sd.nation_name
    FROM 
        FilteredParts fp
    JOIN 
        partsupp ps ON fp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    WHERE 
        fp.p_comment LIKE '%fragile%'
)
SELECT 
    p_name, 
    p_brand, 
    p_retailprice, 
    s_name, 
    nation_name 
FROM 
    CombinedDetails 
ORDER BY 
    p_retailprice DESC;
