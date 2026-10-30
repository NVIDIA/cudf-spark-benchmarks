
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_type,
        rp.p_retailprice,
        rp.p_comment
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
PartSupplier AS (
    SELECT 
        tp.p_partkey,
        tp.p_name,
        sd.s_suppkey,
        sd.s_name,
        sd.s_acctbal,
        tp.p_retailprice
    FROM 
        TopParts tp
    JOIN 
        partsupp ps ON tp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.s_suppkey,
    ps.s_name,
    ps.s_acctbal,
    CONCAT('Supplier ', ps.s_name, ' provides ', ps.p_name, ' with retail price ', CAST(tp.p_retailprice AS DECIMAL(10, 2))) AS supplier_info
FROM 
    PartSupplier ps
JOIN 
    TopParts tp ON ps.p_partkey = tp.p_partkey
ORDER BY 
    ps.p_partkey, ps.s_suppkey;
