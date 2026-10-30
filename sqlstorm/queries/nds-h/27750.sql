WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_details,
        SUM(ps.ps_availqty) AS total_available_qty,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_by_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.part_details,
        rp.total_available_qty
    FROM 
        RankedParts rp
    WHERE 
        rp.rank_by_cost <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_address,
        s.s_phone,
        fp.p_partkey,
        fp.p_name
    FROM 
        Supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        FilteredParts fp ON ps.ps_partkey = fp.p_partkey
)
SELECT 
    s.s_name,
    s.s_address,
    s.s_phone,
    fp.p_name,
    fp.part_details,
    fp.total_available_qty
FROM 
    SupplierDetails s
JOIN 
    FilteredParts fp ON s.p_partkey = fp.p_partkey
ORDER BY 
    fp.total_available_qty DESC, 
    s.s_name ASC;
