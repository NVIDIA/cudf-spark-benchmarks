WITH RankedSuppliers AS (
    SELECT
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT
        rs.s_name,
        rs.rank
    FROM
        RankedSuppliers rs
    WHERE
        rs.rank <= 3
)
SELECT
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_tax,
    o.o_orderdate
FROM
    orders o
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON l.l_partkey = p.p_partkey
WHERE
    s.s_name IN (SELECT s_name FROM TopSuppliers)
    AND l.l_discount > 0.05
ORDER BY
    o.o_orderdate DESC, l.l_extendedprice DESC;
