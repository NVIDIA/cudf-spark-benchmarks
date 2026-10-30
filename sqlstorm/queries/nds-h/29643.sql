WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
top_parts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        rp.p_comment
    FROM 
        ranked_parts rp
    WHERE 
        rp.rank_per_brand <= 5
),
suppliers AS (
    SELECT 
        s.s_name, 
        s.s_address, 
        s.s_phone,
        ps.ps_partkey,
        ps.ps_supplycost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
)
SELECT 
    tp.p_name AS top_part_name,
    tp.p_brand AS top_part_brand,
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    s.s_phone AS supplier_phone,
    s.ps_supplycost AS supplier_cost
FROM 
    top_parts tp
JOIN 
    suppliers s ON tp.p_partkey = s.ps_partkey
ORDER BY 
    tp.p_brand, 
    tp.p_retailprice DESC, 
    s.ps_supplycost ASC;
