
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
TopSegments AS (
    SELECT
        c_mktsegment,
        RANK() OVER (ORDER BY SUM(total_revenue) DESC) as segment_rank
    FROM
        RankedOrders
    GROUP BY
        c_mktsegment
)
SELECT
    s.s_name,
    p.p_name,
    ps.ps_supplycost,
    ps.ps_availqty,
    r.r_name
FROM
    partsupp ps
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    n.n_name IN (SELECT c_mktsegment FROM TopSegments WHERE segment_rank <= 3)
ORDER BY
    r.r_name, s.s_name;
