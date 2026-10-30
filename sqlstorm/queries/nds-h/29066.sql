WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    sd.nation_name,
    sd.region_name
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE rp.price_rank <= 5 AND sd.s_acctbal > 10000
ORDER BY rp.p_retailprice DESC;
