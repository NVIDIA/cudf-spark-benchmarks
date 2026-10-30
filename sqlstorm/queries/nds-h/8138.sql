WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostNations AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        SUM(rs.total_supply_cost) AS total_cost
    FROM
        nation n
    JOIN
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    WHERE
        rs.rank <= 5
    GROUP BY
        n.n_nationkey, n.n_name
)
SELECT
    r.r_name AS region_name,
    hn.n_name AS nation_name,
    hn.total_cost
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    HighCostNations hn ON n.n_nationkey = hn.n_nationkey
ORDER BY
    r.r_name, hn.total_cost DESC;
