
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderstatus = 'F'
),
TopSuppliers AS (
    SELECT
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        s.s_acctbal > 0
    GROUP BY
        ps.ps_suppkey
),
TotalRevenue AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
)
SELECT
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    r.c_acctbal,
    t.revenue,
    CASE 
        WHEN r.rank_order <= 5 THEN 'Top 5 Customer'
        ELSE 'Other'
    END AS customer_category
FROM
    RankedOrders r
LEFT JOIN
    supplier s ON r.c_nationkey = s.s_nationkey
LEFT JOIN
    TotalRevenue t ON r.o_orderkey = t.l_orderkey
WHERE
    r.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND t.revenue IS NOT NULL
ORDER BY
    r.o_orderdate DESC,
    r.o_orderkey;
