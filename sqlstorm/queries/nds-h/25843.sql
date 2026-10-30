SELECT
    CONCAT(c.c_name, ' ', c.c_address) AS customer_info,
    CONCAT(s.s_name, ' ', s.s_address) AS supplier_info,
    p.p_name,
    l.l_quantity,
    l.l_extendedprice,
    o.o_orderdate,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    SUBSTRING(l.l_comment, 1, 20) AS short_comment
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON l.l_partkey = p.p_partkey
WHERE
    p.p_brand LIKE 'Brand#%'
    AND l.l_shipmode IN ('AIR', 'SEA')
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY
    o.o_orderdate DESC, 
    customer_info;