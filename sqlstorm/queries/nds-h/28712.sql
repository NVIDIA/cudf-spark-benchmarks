WITH StringAggregation AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT(LEFT(p.p_name, 10), '...', LEFT(s.s_name, 10), '...') AS shortened_description,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        p.p_comment LIKE '%special%'
    GROUP BY 
        p.p_name, s.s_name
),
FinalOutput AS (
    SELECT 
        part_name,
        supplier_name,
        shortened_description,
        order_count,
        total_quantity,
        ROW_NUMBER() OVER (ORDER BY order_count DESC) AS rank
    FROM 
        StringAggregation
)
SELECT 
    part_name, 
    supplier_name, 
    shortened_description, 
    order_count, 
    total_quantity
FROM 
    FinalOutput
WHERE 
    rank <= 10
ORDER BY 
    order_count DESC;
