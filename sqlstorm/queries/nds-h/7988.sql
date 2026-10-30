
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_name
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopSuppliers AS (
    SELECT
        r.r_name,
        rs.s_name,
        rs.total_available_quantity,
        rs.avg_supply_cost
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.n_name = n.n_name
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        rs.rank <= 3
)
SELECT
    r.r_name AS region,
    COUNT(ts.s_name) AS top_supplier_count,
    SUM(ts.total_available_quantity) AS total_supplies,
    AVG(ts.avg_supply_cost) AS avg_cost_per_supplier
FROM
    TopSuppliers ts
JOIN
    region r ON ts.r_name = r.r_name
GROUP BY
    r.r_name
ORDER BY
    total_supplies DESC, region;
