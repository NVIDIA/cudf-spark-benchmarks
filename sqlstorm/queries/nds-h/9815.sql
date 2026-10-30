WITH RevenuePerSupplier AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY
        s.s_suppkey,
        s.s_name
),
TopSuppliers AS (
    SELECT
        rsp.s_suppkey,
        rsp.s_name,
        rsp.total_revenue,
        RANK() OVER (ORDER BY rsp.total_revenue DESC) AS revenue_rank
    FROM
        RevenuePerSupplier rsp
)
SELECT
    tp.s_suppkey,
    tp.s_name,
    tp.total_revenue,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM
    TopSuppliers tp
JOIN
    supplier s ON tp.s_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    tp.revenue_rank <= 10
ORDER BY
    tp.total_revenue DESC;
