WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        sd.s_suppkey,
        sd.s_name,
        sd.total_cost,
        RANK() OVER (ORDER BY sd.total_cost DESC) AS supplier_rank
    FROM
        SupplierDetails sd
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    ts.s_name AS top_supplier,
    ts.total_cost
FROM
    RankedOrders ro
LEFT JOIN
    lineitem li ON ro.o_orderkey = li.l_orderkey
LEFT JOIN
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE
    ro.order_rank = 1
    AND COALESCE(ts.total_cost, 0) > 500
ORDER BY
    ro.o_orderdate DESC, ro.o_totalprice DESC
LIMIT 100;