SELECT 
    p.p_name,
    substr(p.p_comment, 1, 20) AS short_comment,
    concat(s.s_name, ' - ', n.n_name) AS supplier_info,
    count(distinct o.o_orderkey) AS total_orders,
    sum(l.l_quantity) AS total_quantity,
    avg(l.l_extendedprice) AS avg_price,
    count(l.l_orderkey) FILTER (WHERE l.l_returnflag = 'R') AS return_count,
    date_part('year', o.o_orderdate) AS order_year
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_brand LIKE 'Brand%'
    AND o.o_orderstatus = 'O'
    AND n.n_name IN ('USA', 'Germany')
GROUP BY 
    p.p_name,
    short_comment,
    supplier_info,
    order_year
ORDER BY 
    total_orders DESC,
    total_quantity DESC
LIMIT 50;
