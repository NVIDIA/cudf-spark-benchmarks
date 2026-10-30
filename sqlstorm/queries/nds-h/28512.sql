WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        CASE 
            WHEN LENGTH(p.p_comment) > 10 THEN SUBSTRING(p.p_comment, 1, 10) || '...' 
            ELSE p.p_comment 
        END AS short_comment,
        ROW_NUMBER() OVER (ORDER BY LENGTH(p.p_name) DESC) AS rank
    FROM
        part p
),
TopRatedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_supplycost) AS total_supply_entries,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    ORDER BY
        avg_supply_cost DESC
    LIMIT 5
),
FinalReport AS (
    SELECT
        rp.p_partkey,
        rp.p_name,
        rp.name_length,
        rp.short_comment,
        ts.s_name AS supplier_name,
        ts.avg_supply_cost
    FROM
        RankedParts rp
    JOIN
        TopRatedSuppliers ts ON rp.p_partkey % 5 = ts.s_suppkey % 5
    WHERE
        rp.rank <= 10
)
SELECT 
    *
FROM 
    FinalReport
ORDER BY 
    supplier_name, name_length DESC;
