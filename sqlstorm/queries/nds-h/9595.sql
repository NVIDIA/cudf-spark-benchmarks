WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
filtered_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderpriority,
        r.total_revenue
    FROM
        ranked_orders r
    JOIN
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE
        r.revenue_rank <= 5
)
SELECT
    fo.o_orderkey,
    fo.o_orderdate,
    fo.o_orderpriority,
    fo.total_revenue,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.ps_supplycost
FROM
    filtered_orders fo
JOIN
    lineitem l ON fo.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    fo.total_revenue > 10000
ORDER BY
    fo.total_revenue DESC, fo.o_orderdate ASC;