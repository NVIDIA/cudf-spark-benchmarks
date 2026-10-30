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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%engine%'
),
SupplierPartDetails AS (
    SELECT 
        s.s_name,
        s.s_address,
        s.s_phone,
        ps.ps_availqty,
        ps.ps_supplycost,
        rp.p_name,
        rp.price_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    WHERE 
        s.s_comment LIKE '%quality%'
)
SELECT 
    spd.s_name,
    spd.s_address,
    spd.s_phone,
    spd.ps_availqty,
    spd.ps_supplycost,
    spd.p_name,
    rp.price_rank
FROM 
    SupplierPartDetails spd
JOIN 
    (SELECT DISTINCT p_name, price_rank FROM RankedParts WHERE price_rank <= 3) rp ON spd.p_name = rp.p_name
ORDER BY 
    spd.ps_supplycost DESC;
