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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY LENGTH(p.p_name) DESC) AS rank_by_name_length,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTR(p.p_comment, 1, 10) AS short_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal < 5000
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_type,
    rp.p_size,
    rp.p_container,
    rp.p_retailprice,
    rp.p_comment,
    fs.s_name AS supplier_name,
    fs.s_address AS supplier_address,
    fs.supplier_nation,
    fs.s_acctbal AS supplier_acctbal,
    rp.short_comment,
    rp.comment_length,
    rp.rank_by_name_length
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
ORDER BY 
    rp.rank_by_name_length, 
    fs.s_acctbal DESC;
