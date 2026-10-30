WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' supplied by ', s.s_name) AS part_supplier_info,
        LENGTH(p.p_comment) AS comment_length,
        CASE 
            WHEN ps.ps_availqty < 50 THEN 'Low Stock' 
            WHEN ps.ps_availqty BETWEEN 50 AND 150 THEN 'Moderate Stock' 
            ELSE 'High Stock' 
        END AS stock_level
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedDetails AS (
    SELECT 
        part_supplier_info,
        SUM(ps_availqty) AS total_avail_qty,
        AVG(ps_supplycost) AS avg_supply_cost,
        MAX(comment_length) AS max_comment_length,
        MIN(comment_length) AS min_comment_length,
        stock_level
    FROM 
        PartSupplierDetails
    GROUP BY 
        part_supplier_info, stock_level
)
SELECT 
    stock_level,
    COUNT(*) AS count_of_parts,
    SUM(total_avail_qty) AS total_available_quantity,
    AVG(avg_supply_cost) AS average_supply_cost,
    MIN(min_comment_length) AS min_comment_length_in_stock,
    MAX(max_comment_length) AS max_comment_length_in_stock
FROM 
    AggregatedDetails
GROUP BY 
    stock_level
ORDER BY 
    stock_level DESC;
