SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    n_name,
    extract(YEAR FROM o_orderdate) AS o_year
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01' 
    AND o.o_orderdate < DATE '1996-01-01'
    AND p.p_brand = 'Brand#22'
GROUP BY 
    n_name, o_year
ORDER BY 
    revenue DESC;
