WITH ranked_parts AS (
    SELECT 
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS part_info,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_name
),
top_parts AS (
    SELECT 
        part_info, 
        total_cost
    FROM 
        ranked_parts 
    WHERE 
        rank <= 10
)
SELECT 
    tp.part_info,
    tp.total_cost,
    CASE 
        WHEN tp.total_cost > 1000 THEN 'High Value'
        WHEN tp.total_cost BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS cost_category
FROM 
    top_parts tp
ORDER BY 
    tp.total_cost DESC;
