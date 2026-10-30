WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_type
),
TopParts AS (
    SELECT 
        RP.p_partkey, 
        RP.p_name, 
        RP.p_mfgr, 
        RP.p_type, 
        RP.supplier_count, 
        RP.total_available_quantity
    FROM 
        RankedParts RP
    WHERE 
        RP.rank <= 5
)
SELECT 
    TP.p_name,
    REPLACE(TP.p_mfgr, 'Corp', 'International') AS modified_manufacturer,
    CONCAT('Available from ', TP.supplier_count, ' suppliers and ', 
           TP.total_available_quantity, ' units in stock.') AS availability_info
FROM 
    TopParts TP
WHERE 
    TP.total_available_quantity > 100
ORDER BY 
    TP.supplier_count DESC, TP.total_available_quantity DESC;
