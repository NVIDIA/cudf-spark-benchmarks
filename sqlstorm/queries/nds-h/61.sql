WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        ps.ps_availqty > 0
), AggregatedOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        o.o_orderdate
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
), SupplierOrders AS (
    SELECT
        rs.s_suppkey,
        ao.o_orderkey,
        ao.total_price
    FROM
        RankedSuppliers rs
    LEFT JOIN
        AggregatedOrders ao ON rs.s_suppkey = ao.o_orderkey
    WHERE
        rs.rank = 1
), NullValues AS (
    SELECT
        so.s_suppkey,
        COALESCE(so.total_price, 0) AS total_price
    FROM
        SupplierOrders so
)
SELECT
    r.r_name,
    SUM(nv.total_price) AS total_revenue
FROM
    NullValues nv
LEFT JOIN
    supplier s ON nv.s_suppkey = s.s_suppkey
LEFT JOIN
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY
    r.r_name
HAVING
    SUM(nv.total_price) > (SELECT AVG(total_price) FROM NullValues) 
ORDER BY
    total_revenue DESC;
