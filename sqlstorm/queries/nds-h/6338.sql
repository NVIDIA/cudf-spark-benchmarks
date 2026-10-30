WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
        )
), HighValueOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        o.o_custkey
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate, o.o_custkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), SupplierOrderDetails AS (
    SELECT
        hvo.o_orderkey,
        r.nation_name,
        r.s_name AS supplier_name,
        hvo.total_revenue,
        hvo.o_orderdate
    FROM
        HighValueOrders hvo
    JOIN
        RankedSuppliers r ON hvo.o_custkey = r.s_suppkey
)

SELECT
    sod.o_orderkey,
    sod.nation_name,
    sod.supplier_name,
    sod.total_revenue,
    sod.o_orderdate
FROM
    SupplierOrderDetails sod
ORDER BY
    sod.total_revenue DESC, sod.o_orderdate DESC
LIMIT 10;
