WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS availability_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
top_parts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.total_available_quantity,
        rp.supplier_count,
        r.r_name AS region_name,
        c.c_name AS customer_name
    FROM 
        ranked_parts rp
    JOIN 
        supplier s ON rp.supplier_count > 5
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.total_available_quantity,
    tp.supplier_count,
    tp.region_name,
    tp.customer_name,
    CONCAT(tp.p_name, ' - ', tp.region_name) AS part_region_combo
FROM 
    top_parts tp
WHERE 
    tp.total_available_quantity > 100
ORDER BY 
    tp.total_available_quantity DESC, tp.supplier_count ASC;
