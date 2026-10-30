WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
high_value_orders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        c.c_name,
        c.c_address,
        c.c_phone
    FROM
        ranked_orders ro
    JOIN
        customer c ON ro.o_orderkey = c.c_custkey
    WHERE
        ro.price_rank <= 10
),
order_details AS (
    SELECT
        l.l_orderkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        p.p_name,
        s.s_name
    FROM
        lineitem l
    JOIN
        part p ON l.l_partkey = p.p_partkey
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        l.l_orderkey IN (SELECT o_orderkey FROM high_value_orders)
)
SELECT
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.c_name,
    hvo.c_address,
    hvo.c_phone,
    od.l_quantity,
    od.l_extendedprice,
    od.l_discount,
    od.l_tax,
    od.p_name,
    od.s_name
FROM
    high_value_orders hvo
JOIN
    order_details od ON hvo.o_orderkey = od.l_orderkey
ORDER BY
    hvo.o_orderdate DESC, hvo.o_orderkey;