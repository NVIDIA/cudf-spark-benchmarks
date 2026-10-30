WITH SupplierParts AS (
    SELECT s.s_name AS supplier_name, p.p_name AS part_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
PartDetails AS (
    SELECT supplier_name, part_name, ps_availqty, ps_supplycost,
           CONCAT(part_name, ' supplied by ', supplier_name) AS detailed_info
    FROM SupplierParts
),
RankedParts AS (
    SELECT supplier_name, part_name, ps_availqty, ps_supplycost,
           detailed_info,
           ROW_NUMBER() OVER (PARTITION BY supplier_name ORDER BY ps_supplycost DESC) AS rank
    FROM PartDetails
)
SELECT supplier_name, part_name, ps_availqty, ps_supplycost, detailed_info
FROM RankedParts
WHERE rank <= 5
ORDER BY supplier_name, ps_supplycost DESC;
