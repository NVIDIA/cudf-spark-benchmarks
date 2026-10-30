WITH RankedItems AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        p.p_partkey, p.p_name, s.s_name
),
HighValueItems AS (
    SELECT
        r.*,
        (total_supply_cost / NULLIF(total_available_quantity, 0)) AS cost_per_unit
    FROM
        RankedItems r
    WHERE
        r.rank = 1 AND total_available_quantity > 0
)
SELECT
    h.p_partkey,
    h.p_name,
    h.supplier_name,
    h.total_available_quantity,
    h.total_supply_cost,
    h.cost_per_unit
FROM
    HighValueItems h
ORDER BY
    h.cost_per_unit DESC
LIMIT 10;
