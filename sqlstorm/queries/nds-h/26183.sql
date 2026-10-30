WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%Steel%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplierInfo AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        sp.s_suppkey,
        sp.s_name,
        sp.nation_name,
        sp.region_name
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sp ON ps.ps_suppkey = sp.s_suppkey
    WHERE 
        rp.rn <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_size,
    CONCAT('Supplier: ', psi.s_name, ' | Nation: ', psi.nation_name, ' | Region: ', psi.region_name) AS supplier_info
FROM 
    RankedParts p
JOIN 
    PartSupplierInfo psi ON p.p_partkey = psi.p_partkey
ORDER BY 
    p.p_size DESC, 
    p.p_retailprice DESC;
