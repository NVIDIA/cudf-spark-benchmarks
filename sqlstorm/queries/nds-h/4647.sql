WITH SupplierOrders AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        s.s_suppkey, s.s_name
),
NationRevenue AS (
    SELECT
        n.n_name,
        SUM(so.total_revenue) AS national_revenue
    FROM
        nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN SupplierOrders so ON s.s_suppkey = so.s_suppkey
    GROUP BY
        n.n_name
),
RankedRevenue AS (
    SELECT
        nr.n_name,
        nr.national_revenue,
        RANK() OVER (ORDER BY nr.national_revenue DESC) AS revenue_rank
    FROM
        NationRevenue nr
)
SELECT
    r.r_name AS region_name,
    rr.n_name AS nation_name,
    rr.national_revenue,
    rr.revenue_rank
FROM
    region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN RankedRevenue rr ON n.n_name = rr.n_name
WHERE
    rr.national_revenue IS NOT NULL
    AND rr.revenue_rank <= 5
ORDER BY
    r.r_name, rr.revenue_rank;
