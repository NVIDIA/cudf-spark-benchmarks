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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 100000
),
JoinParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        hvs.s_name,
        hvs.s_acctbal
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        HighValueSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
    WHERE 
        rp.rank <= 3
)
SELECT 
    jp.p_partkey,
    jp.p_name,
    jp.p_brand,
    jp.p_retailprice,
    COUNT(jp.s_name) AS supplier_count,
    AVG(jp.s_acctbal) AS average_acctbal
FROM 
    JoinParts jp
GROUP BY 
    jp.p_partkey, jp.p_name, jp.p_brand, jp.p_retailprice
ORDER BY 
    average_acctbal DESC
LIMIT 10;
