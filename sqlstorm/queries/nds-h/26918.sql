
WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_brand, ' [', p.p_type, ']') AS part_info,
        STRING_AGG(s.s_name, ', ') AS supplier_names,
        STRING_AGG(SUBSTRING(s.s_comment, 1, 20), ' | ') AS supplier_comments,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(COALESCE(l.l_quantity, 0)) AS total_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON c.c_custkey = o.o_custkey
    WHERE 
        p.p_size >= 10 AND 
        p.p_retailprice > 100.00
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type
)
SELECT 
    *,
    CONCAT('Total customers for part ', part_info, ': ', customer_count) AS customer_info,
    CONCAT('Suppliers: ', supplier_names) AS supplier_info,
    CONCAT('Supplier Comments: ', supplier_comments) AS comments_info
FROM 
    StringAggregation
ORDER BY 
    total_quantity DESC
LIMIT 10;
