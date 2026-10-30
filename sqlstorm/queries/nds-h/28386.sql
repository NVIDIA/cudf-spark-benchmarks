WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_comment) DESC) AS rank_per_brand
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 10
), filtered_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        CASE 
            WHEN n.n_name LIKE '%land%' THEN 'Land Nation'
            ELSE 'Other Nation'
        END AS nation_category
    FROM 
        nation n
    WHERE 
        n.n_comment IS NOT NULL
), supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        REPLACE(s.s_address, 'Street', 'St.') AS address_short
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
), combined_info AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        fn.n_name,
        fn.nation_category,
        si.s_name,
        si.address_short
    FROM 
        ranked_parts rp
    JOIN 
        filtered_nations fn ON fn.n_nationkey = rp.p_partkey % 10  
    JOIN 
        supplier_info si ON si.s_suppkey = fn.n_nationkey + 1  
)
SELECT 
    ci.p_partkey,
    ci.p_name,
    ci.p_brand,
    ci.p_type,
    ci.n_name,
    ci.nation_category,
    ci.s_name,
    ci.address_short
FROM 
    combined_info ci
WHERE 
    (ci.nation_category = 'Land Nation' AND ci.p_brand LIKE 'Brand%')
ORDER BY 
    ci.p_brand, ci.p_name;