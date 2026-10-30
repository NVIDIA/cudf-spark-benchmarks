WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
HighValueOrders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name
    FROM
        RankedOrders r
    WHERE
        r.rnk <= 10
),
OrderDetails AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        SUM(l.l_quantity) AS total_quantity,
        s.s_name
    FROM
        lineitem l
    JOIN
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        l.l_orderkey, s.s_name
)
SELECT
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.c_name,
    COALESCE(od.net_revenue, 0) AS total_revenue,
    COALESCE(od.total_quantity, 0) AS total_quantity,
    CASE
        WHEN od.net_revenue IS NOT NULL THEN 'Supplied'
        ELSE 'Not Supplied'
    END AS supply_status
FROM
    HighValueOrders h
LEFT JOIN
    OrderDetails od ON h.o_orderkey = od.l_orderkey
ORDER BY
    h.o_orderdate ASC, h.o_totalprice DESC;