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
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.short_comment,
    si.s_name,
    si.nation_name,
    si.s_phone
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
WHERE rp.rank <= 5
ORDER BY rp.p_type, rp.p_retailprice DESC;
