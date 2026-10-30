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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY LENGTH(p.p_name)) AS rank_length
    FROM part p
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_retailprice,
        rp.p_comment
    FROM RankedParts rp
    WHERE rp.rank_price <= 5 AND rp.rank_length <= 5
),
SupplierPartInfo AS (
    SELECT 
        sp.ps_partkey,
        s.s_name AS supplier_name,
        s.s_address,
        s.s_phone,
        sp.ps_availqty,
        sp.ps_supplycost,
        sp.ps_comment
    FROM partsupp sp
    JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
    WHERE sp.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
CombinedInfo AS (
    SELECT 
        tp.p_partkey,
        tp.p_name,
        tp.p_mfgr,
        tp.p_brand,
        tp.p_type,
        tp.p_retailprice,
        tp.p_comment,
        spi.supplier_name,
        spi.s_address,
        spi.s_phone,
        spi.ps_availqty,
        spi.ps_supplycost,
        spi.ps_comment
    FROM TopParts tp
    JOIN SupplierPartInfo spi ON tp.p_partkey = spi.ps_partkey
)
SELECT 
    c.c_name AS customer_name,
    c.c_address AS customer_address,
    ci.*
FROM customer c
JOIN CombinedInfo ci ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
ORDER BY ci.p_retailprice DESC, ci.supplier_name;
