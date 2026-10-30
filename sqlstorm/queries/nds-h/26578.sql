WITH CombinedData AS (
    SELECT 
        p.p_partkey, 
        CONCAT(p.p_name, ' [', p.p_type, ']') AS part_detail, 
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        r.r_name AS region_name,
        o.o_orderkey, 
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        p.p_partkey, part_detail, supplier_name, customer_name, region_name, o.o_orderkey, o.o_totalprice
)
SELECT 
    part_detail, 
    supplier_name, 
    customer_name, 
    region_name, 
    SUM(o_totalprice) AS total_spent, 
    AVG(line_count) AS avg_lines_per_order
FROM 
    CombinedData
WHERE 
    region_name LIKE '%East%'
GROUP BY 
    part_detail, 
    supplier_name, 
    customer_name, 
    region_name
ORDER BY 
    total_spent DESC;
