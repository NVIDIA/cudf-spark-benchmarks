WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
TopNationalSuppliers AS (
    SELECT
        rn,
        s_suppkey,
        s_name,
        nation_name,
        s_acctbal
    FROM
        RankedSuppliers
    WHERE
        rn <= 3
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND
        o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        o.o_orderkey
),
FinalResult AS (
    SELECT
        ts.nation_name,
        ts.s_name,
        SUM(od.total_revenue) AS total_revenue,
        SUM(od.total_items) AS total_items
    FROM
        TopNationalSuppliers ts
    JOIN
        partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        OrderDetails od ON od.total_items > 0
    GROUP BY
        ts.nation_name,
        ts.s_name
)
SELECT
    nation_name,
    s_name,
    total_revenue,
    total_items
FROM
    FinalResult
ORDER BY
    total_revenue DESC,
    total_items DESC;