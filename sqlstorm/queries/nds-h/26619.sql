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
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 50000
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        r.r_name AS region_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rp.p_name AS part_name,
    rp.p_brand AS brand,
    rp.p_type AS type,
    hs.s_name AS supplier_name,
    hs.s_acctbal AS supplier_account_balance,
    ps.ps_supplycost AS supply_cost,
    ps.ps_availqty AS available_quantity,
    ps.region_name
FROM 
    RankedParts rp
JOIN 
    PartSupplierDetails ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    HighValueSuppliers hs ON ps.ps_suppkey = hs.s_suppkey
WHERE 
    rp.rank <= 5 
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC, hs.s_acctbal DESC;
