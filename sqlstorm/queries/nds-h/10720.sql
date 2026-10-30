SELECT
    l_returnflag,
    l_linestatus,
    SUM(l_quantity) AS sum_quantity,
    SUM(l_extendedprice) AS sum_extendedprice,
    SUM(l_extendedprice * (1 - l_discount)) AS sum_net_price,
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
    AVG(l_quantity) AS avg_quantity,
    AVG(l_extendedprice) AS avg_price,
    AVG(l_discount) AS avg_discount
FROM
    lineitem
WHERE
    l_shipdate >= DATE '1995-01-01'
    AND l_shipdate < DATE '1996-01-01'
GROUP BY
    l_returnflag,
    l_linestatus
ORDER BY
    l_returnflag,
    l_linestatus;
