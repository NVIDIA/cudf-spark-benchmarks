WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        sum(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY sum(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name, p.p_type
),
TopSuppliers AS (
    SELECT
        r.r_name,
        rs.s_name,
        rs.total_supply_cost
    FROM
        RankedSuppliers rs
    JOIN
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        rs.supplier_rank <= 3
)
SELECT
    r.r_name AS region,
    COUNT(DISTINCT ts.s_name) AS top_supplier_count,
    SUM(ts.total_supply_cost) AS total_cost
FROM
    TopSuppliers ts
JOIN
    region r ON ts.r_name = r.r_name
GROUP BY
    r.r_name
ORDER BY
    total_cost DESC;
