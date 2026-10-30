
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_regionkey
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_value,
        n.n_name AS region_name
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.rank <= 3 AND rs.n_regionkey = n.n_nationkey
)
SELECT
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    ts.s_name AS top_supplier,
    ts.total_supply_value
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND l.l_discount > 0.05
ORDER BY
    c.c_acctbal DESC, ts.total_supply_value DESC;
