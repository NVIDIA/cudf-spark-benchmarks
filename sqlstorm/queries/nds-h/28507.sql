WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierPart AS (
    SELECT 
        s.s_name,
        s.s_address,
        rp.p_name,
        rp.p_retailprice
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
)
SELECT 
    sp.s_name AS Supplier_Name,
    sp.s_address AS Supplier_Address,
    sp.p_name AS Part_Name,
    sp.p_retailprice AS Retail_Price
FROM 
    SupplierPart sp
WHERE 
    sp.p_name LIKE '%steel%'
ORDER BY 
    sp.p_retailprice DESC
LIMIT 10;
