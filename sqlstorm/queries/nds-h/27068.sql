WITH TopParts AS (
    SELECT 
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_name, p.p_type
),
RelevantSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_name, s.s_nationkey
),
Combined AS (
    SELECT 
        t.p_name,
        t.total_revenue,
        s.s_name,
        r.r_name AS region,
        s.part_count
    FROM 
        TopParts t
    JOIN 
        RelevantSuppliers s ON t.p_name LIKE '%' || s.s_name || '%'
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        t.revenue_rank <= 5
)
SELECT 
    p_name,
    total_revenue,
    s_name,
    region,
    part_count
FROM 
    Combined
ORDER BY 
    total_revenue DESC;
