WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey,
        o.o_orderdate
),
HighRevenueOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        r.total_revenue
    FROM
        RankedOrders r
    JOIN
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE
        r.revenue_rank <= 10
),
SupplierRevenue AS (
    SELECT
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        HighRevenueOrders hro ON l.l_orderkey = hro.o_orderkey
    GROUP BY
        s.s_name
)
SELECT
    s.s_name,
    s.supplier_revenue,
    ROW_NUMBER() OVER (ORDER BY s.supplier_revenue DESC) AS revenue_rank
FROM
    SupplierRevenue s
WHERE
    s.supplier_revenue > 0
ORDER BY
    s.supplier_revenue DESC;
