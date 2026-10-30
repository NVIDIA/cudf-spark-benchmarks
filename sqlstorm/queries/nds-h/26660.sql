WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size >= 10
),
TopExpensiveParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
)
SELECT 
    tp.p_name AS Part_Name,
    tp.p_brand AS Brand,
    COUNT(sd.s_suppkey) AS Supplier_Count,
    AVG(sd.s_acctbal) AS Average_Account_Balance
FROM 
    TopExpensiveParts tp
JOIN 
    partsupp ps ON tp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
GROUP BY 
    tp.p_name, tp.p_brand
ORDER BY 
    Average_Account_Balance DESC;
