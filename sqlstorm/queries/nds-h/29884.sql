WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        s.s_address,
        ps.ps_availqty,
        ps.ps_supplycost,
        REPLACE(LOWER(p.p_comment), ' ', '-') AS formatted_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
        AND s.s_acctbal > 500.00
),
RegionSummary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.region_name,
    r.total_parts,
    r.total_available_quantity,
    p.formatted_comment
FROM 
    RegionSummary r
JOIN 
    PartSupplierDetails p ON r.total_parts > 5
ORDER BY 
    r.region_name, p.p_name;
