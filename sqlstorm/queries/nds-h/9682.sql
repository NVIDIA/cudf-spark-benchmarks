
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE p.p_size BETWEEN 15 AND 25
),
TopBrands AS (
    SELECT 
        rp.p_brand,
        AVG(rp.p_retailprice) AS avg_price,
        COUNT(rp.p_partkey) AS part_count
    FROM RankedParts rp
    WHERE rp.brand_rank <= 5
    GROUP BY rp.p_brand
),
SupplierNation AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
CustomerCount AS (
    SELECT 
        cm.c_mktsegment,
        COUNT(cm.c_custkey) AS customer_count
    FROM customer cm
    GROUP BY cm.c_mktsegment
)
SELECT 
    tb.p_brand,
    tb.avg_price,
    sn.nation_name,
    sn.supplier_count,
    cc.c_mktsegment,
    cc.customer_count
FROM TopBrands tb
JOIN SupplierNation sn ON tb.p_brand LIKE '%' || sn.nation_name || '%'
JOIN CustomerCount cc ON cc.customer_count > sn.supplier_count
ORDER BY tb.avg_price DESC, sn.supplier_count DESC
LIMIT 10;
