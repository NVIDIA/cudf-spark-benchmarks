
SELECT
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_container,
    p.p_retailprice,
    p.p_comment,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.o_orderdate,
    o.o_orderpriority,
    o.o_clerk,
    o.o_shippriority,
    l.l_orderkey,
    l.l_partkey,
    l.l_suppkey,
    l.l_linenumber,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_tax,
    l.l_returnflag,
    l.l_linestatus,
    l.l_shipdate,
    l.l_commitdate,
    l.l_receiptdate,
    l.l_shipinstruct,
    l.l_shipmode,
    l.l_comment
FROM
    part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE
    CHAR_LENGTH(p.p_name) > 30 AND
    POSITION('important' IN s.s_comment) > 0 AND
    p.p_container LIKE 'BOX%' AND
    r.r_name IN ('ASIA', 'EUROPE') AND
    (o.o_orderstatus = 'O' OR o.o_orderdate > '1997-01-01')
GROUP BY
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_container,
    p.p_retailprice,
    p.p_comment,
    r.r_name,
    n.n_name,
    s.s_name,
    c.c_name,
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.o_orderdate,
    o.o_orderpriority,
    o.o_clerk,
    o.o_shippriority,
    l.l_orderkey,
    l.l_partkey,
    l.l_suppkey,
    l.l_linenumber,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_tax,
    l.l_returnflag,
    l.l_linestatus,
    l.l_shipdate,
    l.l_commitdate,
    l.l_receiptdate,
    l.l_shipinstruct,
    l.l_shipmode,
    l.l_comment
ORDER BY
    r.r_name,
    n.n_name,
    o.o_orderdate DESC;
