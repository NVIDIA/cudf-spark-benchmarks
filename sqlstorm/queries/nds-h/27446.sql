
SELECT 
    CONCAT(
        'Supplier: ', s_name, 
        ', Part: ', p_name, 
        ', Nation: ', n_name, 
        ', Quantity: ', CAST(SUM(l_quantity) AS STRING), 
        ', Total Price: ', CAST(SUM(l_extendedprice * (1 - l_discount)) AS STRING), 
        ', Order Date: ', CAST(MIN(o_orderdate) AS STRING)
    ) AS benchmark_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_brand = 'Brand#45'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    s_name, p_name, n_name
ORDER BY 
    SUM(l_extendedprice * (1 - l_discount)) DESC
LIMIT 100;
