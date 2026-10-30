WITH FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_phone AS supplier_phone,
        r.r_name AS region_name
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        p.p_retailprice > 100.00
        AND p.p_comment LIKE '%special%'
),
AggregateData AS (
    SELECT
        p_name,
        COUNT(*) AS supplier_count,
        AVG(ps_supplycost) AS average_supply_cost
    FROM
        FilteredParts
    GROUP BY
        p_name
)
SELECT
    p.p_name,
    p.supplier_count,
    p.average_supply_cost,
    CONCAT('Total suppliers for ', p.p_name, ': ', p.supplier_count) AS supplier_info
FROM
    AggregateData p
ORDER BY
    p.average_supply_cost DESC;
