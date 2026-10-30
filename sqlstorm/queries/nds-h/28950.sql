WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%special%'
),
Nations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_name LIKE 'U%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        Nations n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    rp.p_size, 
    rp.p_retailprice, 
    sd.s_name AS supplier_name, 
    sd.s_phone AS supplier_phone
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    rp.rnk <= 3
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
