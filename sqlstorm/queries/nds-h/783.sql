WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        RankedSuppliers s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
        AND s.supplier_rank <= 3
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_revenue,
    COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
    CASE 
        WHEN SUM(o.o_totalprice) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Generated'
    END AS revenue_status
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    EXISTS (SELECT 1 FROM TopSuppliers ts WHERE ts.s_suppkey = s.s_suppkey)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0 OR SUM(o.o_totalprice) > 10000
ORDER BY 
    total_revenue DESC;
