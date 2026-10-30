
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM
        RankedOrders r
    WHERE
        r.order_rank <= 10
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name, p.p_partkey
),
CombinedResults AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.total_revenue,
        s.s_name AS supplier_name,
        s.supplier_cost
    FROM
        TopRevenueOrders o
    JOIN
        SupplierDetails s ON o.o_orderkey = s.p_partkey
)
SELECT
    cr.o_orderkey,
    cr.o_orderdate,
    cr.total_revenue,
    cr.supplier_name,
    cr.supplier_cost
FROM
    CombinedResults cr
ORDER BY
    cr.total_revenue DESC, cr.o_orderdate ASC;
