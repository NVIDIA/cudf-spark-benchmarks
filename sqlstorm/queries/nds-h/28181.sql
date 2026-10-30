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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE p.p_size > 15
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        s.s_phone,
        s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 50000
),
AggregatedData AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        sd.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM RankedParts rp
    LEFT JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    LEFT JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    WHERE rp.brand_rank <= 5
    GROUP BY rp.p_partkey, rp.p_name, rp.p_brand, rp.p_retailprice, sd.s_name
)
SELECT 
    ad.p_partkey,
    ad.p_name,
    ad.p_brand,
    ad.p_retailprice,
    ad.supplier_name,
    ad.supplier_count
FROM AggregatedData ad
WHERE ad.supplier_count > 2
ORDER BY ad.p_retailprice DESC, ad.p_name ASC;
