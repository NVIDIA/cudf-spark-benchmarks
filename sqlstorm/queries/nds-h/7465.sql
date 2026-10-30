WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE
        p.p_size IN (10, 20, 30)
    GROUP BY
        p.p_partkey, p.p_name, p.p_retailprice
),
RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
)
SELECT
    r.p_partkey,
    r.p_name,
    r.p_retailprice,
    r.total_cost,
    s.s_name,
    s.num_parts,
    o.o_orderkey,
    o.o_orderdate,
    o.total_revenue
FROM
    RankedParts r
JOIN
    RankedSuppliers s ON r.p_partkey = s.num_parts
JOIN
    OrderSummary o ON o.total_revenue > (SELECT AVG(total_revenue) FROM OrderSummary)
ORDER BY
    r.total_cost DESC,
    o.total_revenue ASC
LIMIT 100;