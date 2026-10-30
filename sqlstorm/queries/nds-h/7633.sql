WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name, p.p_name
),
TopSuppliers AS (
    SELECT
        sp.s_suppkey,
        sp.s_name,
        SUM(sp.total_available_qty) AS total_qty_supplied
    FROM
        SupplierParts sp
    GROUP BY
        sp.s_suppkey, sp.s_name
    ORDER BY
        total_qty_supplied DESC
    LIMIT 10
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    ts.s_name,
    ts.total_qty_supplied
FROM
    RankedOrders ro
JOIN
    TopSuppliers ts ON ts.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_name LIKE '%Widget%'
        )
        ORDER BY ps.ps_supplycost ASC
        LIMIT 1
    )
WHERE
    ro.revenue_rank <= 5
ORDER BY
    ro.total_revenue DESC;
