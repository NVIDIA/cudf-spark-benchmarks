
WITH PartSupplierDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_retailprice,
        ps.ps_supplycost,
        CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Manufacturer: ', p.p_mfgr) AS part_description,
        ps.ps_availqty,
        CASE 
            WHEN ps.ps_availqty < 50 THEN 'Low Availability'
            WHEN ps.ps_availqty BETWEEN 50 AND 200 THEN 'Medium Availability'
            ELSE 'High Availability'
        END AS availability_status
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        s.s_phone,
        s.s_acctbal,
        CONCAT('Supplier: ', s.s_name, ', Phone: ', s.s_phone) AS supplier_description
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
CombinedDetails AS (
    SELECT
        psd.part_description,
        psd.availability_status,
        sd.supplier_description,
        CASE
            WHEN psd.ps_supplycost < 50 THEN 'Cost Sensitive'
            ELSE 'Cost Moderate'
        END AS supply_cost_category,
        psd.ps_supplycost -- Added this column to fix the GROUP BY clause
    FROM
        PartSupplierDetails psd
    JOIN
        SupplierDetails sd ON psd.p_partkey = sd.s_suppkey
)
SELECT
    part_description,
    availability_status,
    supplier_description,
    supply_cost_category
FROM
    CombinedDetails
WHERE
    availability_status = 'Low Availability'
ORDER BY
    ps_supplycost DESC
LIMIT 10;
