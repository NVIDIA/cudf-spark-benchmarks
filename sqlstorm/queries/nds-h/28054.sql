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
        COUNT(ps.ps_partkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p 
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_brand, 
        rp.p_retailprice, 
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count > 5 AND rp.rank_by_price <= 10
)
SELECT 
    fp.p_partkey, 
    fp.p_name AS part_name, 
    fp.p_brand AS brand_name, 
    fp.p_retailprice AS retail_price, 
    (SELECT COUNT(DISTINCT l.l_orderkey) 
     FROM lineitem l 
     JOIN orders o ON l.l_orderkey = o.o_orderkey 
     WHERE l.l_partkey = fp.p_partkey AND o.o_orderstatus = 'F') AS finished_orders
FROM 
    FilteredParts fp
ORDER BY 
    fp.p_retailprice DESC;
