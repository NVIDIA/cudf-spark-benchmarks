
WITH StringAggregates AS (
    SELECT
        s.s_name AS supplier_name,
        CONCAT('Supplier: ', s.s_name, ' | Address: ', s.s_address, ' | Phone: ', s.s_phone) AS detailed_info,
        LENGTH(s.s_comment) AS comment_length,
        COUNT(ps.ps_partkey) AS parts_supplied
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_comment
),
HighVolumeSuppliers AS (
    SELECT
        supplier_name,
        detailed_info,
        comment_length,
        parts_supplied,
        CASE WHEN comment_length != 0 THEN TRUE ELSE FALSE END AS comment_non_empty
    FROM
        StringAggregates
    WHERE
        parts_supplied > 5
)
SELECT
    supplier_name,
    detailed_info,
    comment_length,
    CASE 
        WHEN comment_non_empty THEN 'This supplier has additional comments.' 
        ELSE 'No comments available.'
    END AS comment_status
FROM
    HighVolumeSuppliers
ORDER BY
    parts_supplied DESC, comment_length ASC
LIMIT 10;
