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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p 
    WHERE 
        p.p_comment LIKE '%special%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000.00
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT('Supply Cost: ', ps.ps_supplycost, ', Available Quantity: ', ps.ps_availqty) AS supply_info
    FROM 
        partsupp ps
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
)
SELECT 
    rp.p_name,
    rp.p_type,
    rp.p_retailprice,
    sd.s_name,
    sd.nation_name,
    psi.supply_info
FROM 
    RankedParts rp
JOIN 
    PartSupplierInfo psi ON rp.p_partkey = psi.ps_partkey
JOIN 
    SupplierDetails sd ON psi.ps_suppkey = sd.s_suppkey
WHERE 
    rp.rnk <= 5
ORDER BY 
    rp.p_type, rp.p_retailprice DESC;
