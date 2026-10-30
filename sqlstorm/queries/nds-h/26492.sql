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
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 0
),
FullSupplierData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name,
        r.r_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
FinalResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        fs.s_name AS supplier_name,
        fs.s_address AS supplier_address,
        fs.n_name AS nation_name,
        fs.r_name AS region_name,
        rp.price_rank
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        FullSupplierData fs ON ps.ps_suppkey = fs.s_suppkey
    WHERE 
        rp.price_rank <= 5 AND fs.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    p_partkey,
    p_name,
    supplier_name,
    supplier_address,
    nation_name,
    region_name
FROM 
    FinalResults
ORDER BY 
    price_rank, nation_name;
