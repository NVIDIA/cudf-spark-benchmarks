WITH  cte AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
top_suppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        supplier s
    JOIN
        lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
order_stats AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        c.c_mktsegment,
        o.o_orderdate,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS segment_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY
        o.o_orderkey, o.o_orderstatus, c.c_mktsegment, o.o_orderdate
)
SELECT
    n.n_name,
    r.r_name,
    SUM(os.order_total) AS total_orders,
    COUNT(DISTINCT ts.s_suppkey) AS unique_suppliers,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(ts.total_revenue) AS max_revenue,
    MIN(ts.total_revenue) AS min_revenue
FROM
    nation n
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN
    order_stats os ON o.o_orderkey = os.o_orderkey
LEFT JOIN
    top_suppliers ts ON o.o_orderkey = ts.s_suppkey
LEFT JOIN
    cte p ON p.p_partkey = ts.s_suppkey
WHERE
    os.segment_rank <= 5 AND ts.revenue_rank <= 10
GROUP BY
    n.n_name, r.r_name
ORDER BY
    total_orders DESC, n.n_name;
