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
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.p_container,
        rp.p_retailprice,
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.price_rank <= 5
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_mfgr,
    fp.p_brand,
    fp.p_type,
    fp.p_size,
    fp.p_container,
    fp.p_retailprice,
    fp.supplier_count,
    CONCAT('Part: ', fp.p_name, ', Brand: ', fp.p_brand, ', Retail Price: ', CAST(fp.p_retailprice AS STRING), 
           ', Suppliers: ', CAST(fp.supplier_count AS STRING)) AS part_summary
FROM 
    FilteredParts fp
ORDER BY 
    fp.p_brand, fp.p_retailprice DESC;
