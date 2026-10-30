
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address,
        CONCAT(s.s_name, ' - ', s.s_address) AS full_details, 
        LENGTH(CONCAT(s.s_name, ' - ', s.s_address)) AS detail_length
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        CONCAT(p.p_name, ' [', p.p_size, ']', ' (', p.p_type, ')') AS part_description,
        LENGTH(CONCAT(p.p_name, ' [', p.p_size, ']', ' (', p.p_type, ')')) AS description_length
    FROM 
        part p
),
CombinedData AS (
    SELECT 
        sd.s_suppkey,
        pd.p_partkey,
        sd.full_details,
        pd.part_description,
        sd.detail_length,
        pd.description_length
    FROM 
        SupplierDetails sd
    JOIN 
        partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN 
        PartDetails pd ON ps.ps_partkey = pd.p_partkey
),
FinalResults AS (
    SELECT 
        s_suppkey, 
        p_partkey, 
        full_details,
        part_description,
        detail_length + description_length AS total_length
    FROM 
        CombinedData
)
SELECT 
    s.s_suppkey, 
    s.s_name, 
    MAX(f.total_length) AS max_string_length,
    AVG(f.total_length) AS avg_string_length
FROM 
    FinalResults f
JOIN 
    supplier s ON f.s_suppkey = s.s_suppkey
GROUP BY 
    s.s_suppkey, 
    s.s_name
ORDER BY 
    max_string_length DESC
LIMIT 10;
