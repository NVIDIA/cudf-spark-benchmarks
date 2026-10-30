WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(tr.total_revenue, 0) AS total_revenue,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    CASE 
        WHEN COUNT(DISTINCT rs.s_suppkey) = 0 THEN 'No Suppliers'
        ELSE 'Has Suppliers'
    END AS supplier_status
FROM 
    part p
LEFT JOIN 
    TotalSales tr ON p.p_partkey = tr.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, tr.total_revenue
HAVING 
    COALESCE(tr.total_revenue, 0) > 5000
ORDER BY 
    total_revenue DESC;