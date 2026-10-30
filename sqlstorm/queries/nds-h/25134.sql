
SELECT
    CONCAT(
        'Supplier: ', s.s_name, 
        ', Region: ', r.r_name, 
        ', Total Order Quantity: ', SUM(l.l_quantity), 
        ', Average Price: ', AVG(l.l_extendedprice), 
        ', Comment: ', p.p_comment
    ) AS supplier_info
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_name LIKE '%rubber%' AND
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_name, r.r_name, p.p_comment
ORDER BY
    SUM(l.l_quantity) DESC
LIMIT 10;
