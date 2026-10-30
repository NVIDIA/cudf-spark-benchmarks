WITH RevenueSummary AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate >= DATE '2000-01-01' AND o.o_orderdate < DATE '2001-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY
        n.n_name
),
TopNations AS (
    SELECT
        nation_name,
        total_revenue,
        order_count,
        customer_count,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        RevenueSummary
)
SELECT
    nation_name,
    total_revenue,
    order_count,
    customer_count
FROM
    TopNations
WHERE
    revenue_rank <= 10
ORDER BY
    total_revenue DESC;
