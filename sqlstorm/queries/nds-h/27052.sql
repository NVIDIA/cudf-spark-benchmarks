WITH SupplierParts AS (
    SELECT
        s.s_name,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_name,
        p.p_name,
        p.p_brand
),
RankedSuppliers AS (
    SELECT
        s_name,
        p_name,
        p_brand,
        total_available_qty,
        total_supplycost,
        RANK() OVER (PARTITION BY p_brand ORDER BY total_supplycost DESC) AS rank
    FROM
        SupplierParts
)
SELECT
    r.s_name AS supplier_name,
    r.p_name AS part_name,
    r.p_brand AS part_brand,
    r.total_available_qty,
    r.total_supplycost
FROM
    RankedSuppliers r
WHERE
    r.rank <= 5
ORDER BY
    r.p_brand,
    r.total_supplycost DESC;
