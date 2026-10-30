
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(CASE 
        WHEN s.rn = 1 THEN s.s_name 
        ELSE NULL 
    END) AS top_supplier,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(CASE 
        WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE NULL 
    END) AS avg_discounted_price
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    NationRegion nr ON c.c_nationkey = nr.n_nationkey
WHERE 
    (p.p_size BETWEEN 1 AND 10 OR p.p_brand LIKE 'Brand%')
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1998-10-01'
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) IS NOT NULL
ORDER BY 
    total_revenue DESC
LIMIT 100;
