WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY nation ORDER BY total_supply_cost DESC) AS rank
    FROM
        RankedSuppliers
)
SELECT
    ps.ps_partkey,
    p.p_name,
    t.s_name AS top_supplier_name,
    t.total_supply_cost
FROM
    partsupp ps
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    TopSuppliers t ON ps.ps_suppkey = t.s_suppkey
WHERE
    t.rank = 1
ORDER BY
    p.p_name,
    t.total_supply_cost DESC
LIMIT 100;
