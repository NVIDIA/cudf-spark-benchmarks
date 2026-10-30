WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
TopNOrders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_mktsegment
    FROM
        RankedOrders r
    WHERE
        r.rank <= 10
),
SupplierDetails AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_name,
    o.c_mktsegment,
    s.s_name,
    s.s_acctbal
FROM
    TopNOrders o
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    SupplierDetails s ON l.l_suppkey = s.ps_suppkey
ORDER BY
    o.o_totalprice DESC, o.o_orderdate ASC;
