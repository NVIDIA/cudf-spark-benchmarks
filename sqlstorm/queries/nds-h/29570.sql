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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
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
        LENGTH(s.s_comment) > 50
), 
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        ps.ps_comment,
        rp.brand_rank
    FROM 
        partsupp ps
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    JOIN 
        FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
)
SELECT 
    p.p_name, 
    s.s_name, 
    ps.ps_availqty, 
    ps.ps_supplycost, 
    ps.ps_comment
FROM 
    PartSupplierDetails ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    ps.brand_rank <= 5
ORDER BY 
    ps.ps_supplycost DESC, 
    p.p_name;
