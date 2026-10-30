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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE LENGTH(p.p_name) > 10
),
SelectedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        SUBSTRING(s.s_comment, 1, 30) AS short_comment
    FROM supplier s
    WHERE s.s_acctbal > 5000
)
SELECT 
    rp.p_name, 
    rp.p_mfgr, 
    rp.rank, 
    ss.s_name AS supplier_name, 
    ss.short_comment 
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN SelectedSuppliers ss ON ps.ps_suppkey = ss.s_suppkey
WHERE rp.rank <= 5
ORDER BY rp.p_retailprice DESC, ss.s_name;
