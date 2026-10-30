WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
SupplierPartSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey,
        s.s_name
),
LineItemDetails AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM
        lineitem l
    WHERE
        l.l_shipdate < cast('1998-10-01' as date)
    GROUP BY
        l.l_orderkey
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name AS customer_name,
    SUM(l.revenue) AS total_lineitem_revenue,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    sp.s_name AS supplier_name,
    sp.total_available_qty,
    sp.total_supply_cost
FROM
    RankedOrders ro
LEFT JOIN
    LineItemDetails l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN
    SupplierPartSummary sp ON l.l_orderkey = sp.s_suppkey 
WHERE
    ro.rank = 1
GROUP BY
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    sp.s_name,
    sp.total_available_qty,
    sp.total_supply_cost
ORDER BY
    ro.o_totalprice DESC
LIMIT 100;