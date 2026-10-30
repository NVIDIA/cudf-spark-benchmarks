WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'F'
),

high_value_lines AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(*) AS total_items
    FROM
        lineitem l
    JOIN
        ranked_orders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY
        l.l_orderkey
)

SELECT
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    r.o_totalprice,
    COALESCE(hvl.total_sales, 0) AS total_sales,
    COALESCE(hvl.total_items, 0) AS total_items
FROM
    ranked_orders r
LEFT JOIN
    high_value_lines hvl ON r.o_orderkey = hvl.l_orderkey
WHERE
    r.rn <= 5
ORDER BY
    r.o_orderdate DESC, r.o_totalprice DESC;
