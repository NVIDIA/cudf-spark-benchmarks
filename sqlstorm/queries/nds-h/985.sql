WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerSegment AS (
    SELECT
        c.c_nationkey,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_nationkey, c.c_mktsegment
),
RecentLineItems AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
    WHERE
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '6 months'
    GROUP BY
        l.l_orderkey
)
SELECT
    R.order_rank,
    R.o_orderkey,
    R.o_totalprice,
    S.s_name,
    S.total_available,
    C.c_mktsegment,
    C.total_orders,
    C.total_spent,
    COALESCE(L.total_revenue, 0) AS recent_revenue
FROM
    RankedOrders R
JOIN SupplierStats S ON R.o_orderkey = S.s_suppkey
LEFT JOIN CustomerSegment C ON S.s_suppkey = C.c_nationkey
LEFT JOIN RecentLineItems L ON R.o_orderkey = L.l_orderkey
WHERE
    R.order_rank <= 10
    AND (C.total_orders IS NOT NULL OR C.total_spent > 1000)
ORDER BY
    R.o_totalprice DESC;