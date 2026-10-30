WITH ranked_sales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'AMERICA' 
    GROUP BY 
        p.p_partkey, p.p_name
),
top_sales AS (
    SELECT 
        p_partkey,
        p_name,
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.p_partkey,
    t.p_name,
    t.total_sales,
    s.s_name AS supplier_name,
    COUNT(DISTINCT(o.o_orderkey)) AS number_of_orders
FROM 
    top_sales t
JOIN 
    partsupp ps ON t.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    t.p_partkey, t.p_name, t.total_sales, s.s_name
ORDER BY 
    t.total_sales DESC;
