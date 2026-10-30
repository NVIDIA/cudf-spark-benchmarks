WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        REPLACE(UPPER(p.p_comment), ' ', '-') AS modified_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_retailprice
    FROM 
        part p
    WHERE 
        p.p_size > 0
),
supplier_nations AS (
    SELECT DISTINCT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name LIKE 'A%' AND s.s_acctbal > 1000
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.modified_comment,
    sn.nation_name,
    rp.rank_by_retailprice
FROM 
    ranked_parts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier_nations sn ON ps.ps_suppkey = sn.s_suppkey
WHERE 
    rp.rank_by_retailprice <= 5
ORDER BY 
    rp.modified_comment, sn.nation_name;
