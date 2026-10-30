
WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s_stats.total_parts,
        s_stats.total_available_quantity,
        ROW_NUMBER() OVER (ORDER BY s_stats.total_cost DESC) AS rn
    FROM 
        supplier_stats s_stats
    JOIN 
        supplier s ON s_stats.s_suppkey = s.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(tso.total_parts, 0) AS parts_total,
    COALESCE(tso.total_available_quantity, 0) AS available_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Available'
    END AS revenue_status
FROM 
    part AS p
LEFT JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    top_suppliers AS tso ON tso.s_suppkey = l.l_suppkey
WHERE 
    p.p_retailprice BETWEEN 10 AND 100
    AND l.l_shipdate >= DATE '1997-01-01'
GROUP BY 
    p.p_partkey, p.p_name, tso.total_parts, tso.total_available_quantity
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    revenue DESC;
