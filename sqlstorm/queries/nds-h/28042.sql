WITH RankedParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_mfgr,
           p.p_brand,
           p.p_type,
           p.p_size,
           p.p_container,
           p.p_retailprice,
           p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
), FilteredSupplier AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_address,
           s.s_phone,
           s.s_acctbal,
           SUBSTRING(s.s_comment, 1, 40) AS truncated_comment
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
), SupplierDetails AS (
    SELECT fs.s_suppkey,
           fs.s_name,
           fs.s_address,
           fs.truncated_comment,
           COUNT(ps.ps_partkey) AS total_parts
    FROM FilteredSupplier fs
    JOIN partsupp ps ON fs.s_suppkey = ps.ps_suppkey
    GROUP BY fs.s_suppkey, fs.s_name, fs.s_address, fs.truncated_comment
), FinalResults AS (
    SELECT rp.p_partkey,
           rp.p_name,
           rp.p_mfgr,
           rp.p_brand,
           rp.p_type,
           rp.p_size,
           rp.p_retailprice,
           sd.s_name AS supplier_name,
           sd.total_parts
    FROM RankedParts rp
    JOIN SupplierDetails sd ON rp.p_partkey = sd.s_suppkey
    WHERE rp.brand_rank <= 5 AND rp.p_size IN (10, 20, 30)
)

SELECT DISTINCT f.p_name,
                f.p_brand,
                f.supplier_name,
                f.p_retailprice
FROM FinalResults f
ORDER BY f.p_retailprice DESC, f.p_name;
