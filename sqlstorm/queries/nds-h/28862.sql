WITH processed_names AS (
    SELECT 
        p_partkey,
        LOWER(p_name) AS lower_name,
        UPPER(p_name) AS upper_name,
        LENGTH(p_name) AS name_length,
        REPLACE(p_name, ' ', '') AS name_no_spaces
    FROM 
        part
),
nation_supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' (', n.n_name, ')') AS full_name,
        SUBSTR(s.s_comment, 1, 30) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
count_orders AS (
    SELECT 
        o.o_custkey,
        COUNT(*) AS total_orders
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    pn.lower_name,
    pn.upper_name,
    pn.name_length,
    ns.full_name,
    ns.short_comment,
    co.total_orders
FROM 
    processed_names pn
JOIN 
    partsupp ps ON pn.p_partkey = ps.ps_partkey
JOIN 
    nation_supplier ns ON ps.ps_suppkey = ns.s_suppkey
LEFT JOIN 
    count_orders co ON ns.s_suppkey = co.o_custkey
WHERE 
    pn.name_no_spaces LIKE '%steel%'
ORDER BY 
    pn.name_length DESC, 
    ns.nation_name;
