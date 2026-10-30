
WITH string_metrics AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        LOWER(p.p_brand) AS lower_brand,
        UPPER(p.p_type) AS upper_type,
        REPLACE(p.p_container, ' ', '_') AS container_modified,
        CONCAT('Part:', p.p_partkey, ' - ', p.p_name) AS part_description
    FROM 
        part p
),
supplier_metrics AS (
    SELECT 
        s.s_suppkey,
        CONCAT(s.s_name, ', ', s.s_address) AS full_supplier_info,
        LENGTH(s.s_comment) AS supplier_comment_length,
        REPLACE(s.s_comment, 'Supplier', 'Supplier_X') AS adjusted_comment,
        s.s_nationkey
    FROM 
        supplier s
),
nation_metrics AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        UPPER(SUBSTRING(n.n_comment, 1, 25)) AS short_comment 
    FROM 
        nation n
),
joined_metrics AS (
    SELECT 
        sm.p_partkey,
        sm.name_length,
        sm.comment_length,
        sm.lower_brand,
        sm.upper_type,
        sm.container_modified,
        sm.part_description,
        sup.full_supplier_info,
        sup.supplier_comment_length,
        sup.adjusted_comment,
        nat.n_name,
        nat.short_comment
    FROM 
        string_metrics sm
    JOIN 
        partsupp ps ON sm.p_partkey = ps.ps_partkey
    JOIN 
        supplier_metrics sup ON ps.ps_suppkey = sup.s_suppkey
    JOIN 
        nation_metrics nat ON sup.s_nationkey = nat.n_nationkey
)
SELECT 
    *,
    100.0 * (comment_length + supplier_comment_length) / NULLIF(name_length, 0) AS comment_to_name_ratio
FROM 
    joined_metrics
WHERE 
    name_length > 5 AND supplier_comment_length < 150
ORDER BY 
    name_length DESC, short_comment;
