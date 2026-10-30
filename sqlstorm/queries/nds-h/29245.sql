WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_name LIKE '%steel%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000
),
DetailedPartSupplier AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        sp.ps_availqty,
        sp.ps_supplycost,
        sp.ps_comment,
        sd.s_name AS supplier_name,
        sd.s_address AS supplier_address,
        sd.s_phone AS supplier_phone
    FROM RankedParts rp
    JOIN partsupp sp ON rp.p_partkey = sp.ps_partkey
    JOIN SupplierDetails sd ON sp.ps_suppkey = sd.s_suppkey
    WHERE rp.rn <= 5
)
SELECT 
    dps.p_partkey,
    dps.p_name,
    dps.ps_availqty,
    dps.ps_supplycost,
    CONCAT('Supplier: ', dps.supplier_name, ', Address: ', dps.supplier_address, ', Phone: ', dps.supplier_phone) AS supplier_info,
    CONCAT('Part Type: ', rp.p_type, ' | Retail Price: ', rp.p_retailprice) AS extended_info
FROM DetailedPartSupplier dps
JOIN RankedParts rp ON dps.p_partkey = rp.p_partkey
ORDER BY dps.ps_supplycost DESC;
