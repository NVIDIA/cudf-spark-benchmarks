WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal)
            FROM supplier
            WHERE s_acctbal IS NOT NULL
        )
) 

SELECT 
    n.n_name AS nation,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Generated'
    END AS revenue_status
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100.00
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
    AND EXISTS (
        SELECT 1 
        FROM RankedSuppliers rs 
        WHERE rs.s_suppkey = s.s_suppkey 
        AND rs.rnk <= 3
    )
GROUP BY 
    n.n_name, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    nation, total_revenue DESC
LIMIT 10;