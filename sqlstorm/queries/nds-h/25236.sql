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
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000 
        AND s.s_comment LIKE '%reliable%'
),
JoinResults AS (
    SELECT 
        rp.p_name,
        rp.p_mfgr,
        fs.s_name,
        fs.s_address,
        fs.s_acctbal,
        rp.rank
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
    WHERE 
        rp.rank <= 5
)
SELECT 
    p_name,
    p_mfgr,
    s_name,
    s_address,
    s_acctbal,
    COUNT(*) AS supplier_count
FROM 
    JoinResults
GROUP BY 
    p_name, 
    p_mfgr, 
    s_name, 
    s_address, 
    s_acctbal
ORDER BY 
    supplier_count DESC, 
    p_name;
