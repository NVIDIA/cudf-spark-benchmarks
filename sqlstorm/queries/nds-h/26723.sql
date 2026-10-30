WITH supplier_info AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        MAX(length(s.s_comment)) AS max_comment_length
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
nation_info AS (
    SELECT 
        n.n_nationkey,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    si.supplier_name,
    ni.nation_name,
    si.total_parts,
    si.total_supply_cost,
    si.max_comment_length,
    ni.total_suppliers,
    CONCAT(si.supplier_name, ' from ', ni.nation_name, ' has ', si.total_parts, ' parts with a max comment length of ', si.max_comment_length, ' characters.') AS summary_statement
FROM 
    supplier_info si
JOIN 
    nation_info ni ON si.s_nationkey = ni.n_nationkey
WHERE 
    si.total_parts > 10
ORDER BY 
    si.total_supply_cost DESC, si.max_comment_length ASC;
