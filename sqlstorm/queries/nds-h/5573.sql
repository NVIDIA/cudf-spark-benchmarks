WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.revenue
    FROM
        RankedOrders r
    WHERE
        r.revenue_rank <= 10
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT
    tor.o_orderkey,
    tor.o_orderdate,
    tor.revenue,
    sd.s_name,
    sd.nation
FROM
    TopRevenueOrders tor
JOIN
    lineitem l ON tor.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
ORDER BY
    tor.revenue DESC, tor.o_orderdate ASC;