WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        COUNT(ps.ps_partkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment
),
FilteredParts AS (
    SELECT 
        rp.*,
        CONCAT('Brand: ', rp.p_brand, ' | Name: ', rp.p_name) AS part_description
    FROM RankedParts rp
    WHERE rp.supplier_count > 5
)

SELECT 
    fp.part_description,
    fp.p_retailprice,
    REPLACE(fp.p_comment, 'xxx', 'yyy') AS modified_comment
FROM FilteredParts fp
WHERE fp.rank <= 10
ORDER BY fp.p_retailprice DESC;
