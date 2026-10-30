SELECT
    l.l_returnflag,
    l.l_linestatus,
    SUM(l.l_quantity) AS sum_qty,
    SUM(l.l_extendedprice) AS sum_base_price,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS sum_disc_price,
    SUM(l.l_extendedprice * (1 - l.l_discount) * (1 + l.l_tax)) AS sum_charge,
    AVG(l.l_discount) AS avg_discount,
    COUNT(l.l_linestatus) AS count_order
FROM
    lineitem l
WHERE
    l.l_shipdate >= DATE '1995-01-01'
    AND l.l_shipdate < DATE '1996-01-01'
GROUP BY
    l.l_returnflag,
    l.l_linestatus
ORDER BY
    l.l_returnflag,
    l.l_linestatus;
