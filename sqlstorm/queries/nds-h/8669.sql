WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
HighValueOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM
        RankedOrders ro
    WHERE
        ro.rank_order <= 5
),
LineItemDetails AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_suppkey) AS number_of_suppliers
    FROM
        lineitem l
    JOIN
        HighValueOrders h ON l.l_orderkey = h.o_orderkey
    GROUP BY
        l.l_orderkey
)
SELECT
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.c_name,
    ld.total_sales,
    ld.number_of_suppliers
FROM
    HighValueOrders h
JOIN
    LineItemDetails ld ON h.o_orderkey = ld.l_orderkey
ORDER BY
    h.o_totalprice DESC, ld.total_sales DESC;