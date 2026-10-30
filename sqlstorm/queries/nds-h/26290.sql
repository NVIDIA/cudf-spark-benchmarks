
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
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    sd.nation_name,
    sd.s_acctbal,
    COALESCE(LAG(rp.p_name) OVER (ORDER BY rp.price_rank), 'None') AS previous_part_name,
    CONCAT('Retail price: ', CAST(rp.p_retailprice AS STRING)) AS formatted_price,
    LENGTH(rp.p_comment) AS comment_length
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    rp.price_rank = 1 
    AND sd.s_acctbal > 5000
GROUP BY 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name,
    sd.nation_name,
    sd.s_acctbal,
    rp.p_comment,
    rp.price_rank
ORDER BY 
    rp.p_retailprice DESC;
