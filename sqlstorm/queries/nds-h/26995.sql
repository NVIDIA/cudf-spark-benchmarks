WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        LEAST(LENGTH(p.p_name), LENGTH(p.p_brand), LENGTH(p.p_type)) AS min_length,
        GREATEST(LENGTH(p.p_name), LENGTH(p.p_brand), LENGTH(p.p_type)) AS max_length,
        (LENGTH(p.p_name) + LENGTH(p.p_brand) + LENGTH(p.p_type)) / 3.0 AS avg_length,
        RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.min_length,
        rp.max_length,
        rp.avg_length,
        rp.price_rank,
        s.s_name AS supplier_name,
        n.n_name AS nation_name
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        rp.min_length > 10
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    fp.p_type,
    fp.min_length,
    fp.max_length,
    fp.avg_length,
    fp.price_rank,
    fp.supplier_name,
    fp.nation_name
FROM 
    FilteredParts fp
WHERE 
    fp.price_rank <= 10
ORDER BY 
    fp.avg_length DESC, fp.max_length ASC;
