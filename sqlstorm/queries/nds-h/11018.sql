SELECT 
    l.l_returnflag,
    l.l_linestatus,
    SUM(l.l_quantity) AS sum_quantity,
    SUM(l.l_extendedprice) AS sum_extendedprice,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS sum_discounted_price,
    COUNT(distinct o.o_orderkey) AS count_orders,
    MIN(o.o_orderdate) AS min_orderdate,
    MAX(o.o_orderdate) AS max_orderdate
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1996-04-01'
GROUP BY 
    l.l_returnflag, l.l_linestatus
ORDER BY 
    l.l_returnflag, l.l_linestatus;
