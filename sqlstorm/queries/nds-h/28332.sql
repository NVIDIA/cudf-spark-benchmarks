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
    WHERE 
        p.p_comment LIKE '%special%'
), 
TopPartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_supplycost,
        s.s_name,
        DENSE_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_comment NOT LIKE '%cheap%'
), 
PartDetails AS (
    SELECT 
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_retailprice,
        tps.s_name,
        tps.ps_supplycost
    FROM 
        RankedParts rp
    JOIN 
        TopPartSuppliers tps ON rp.p_partkey = tps.ps_partkey
    WHERE 
        rp.brand_rank <= 5 AND tps.supplier_rank <= 3
) 
SELECT 
    p_name,
    p_mfgr,
    p_brand,
    p_retailprice,
    s_name,
    ps_supplycost,
    CONCAT('Details for ', p_name, ': ', p_mfgr, ', ', p_brand, ', Price: ', p_retailprice, ', Supplier: ', s_name, ' (Cost: ', ps_supplycost, ')') AS detailed_info
FROM 
    PartDetails
ORDER BY 
    p_brand, p_retailprice DESC;
