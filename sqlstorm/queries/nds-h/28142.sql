WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_address, ', ', n.n_name) AS full_address,
        s.s_phone,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, s.s_phone
),
SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.full_address,
        s.s_phone,
        s.part_count,
        s.total_supplycost,
        RANK() OVER (ORDER BY s.part_count DESC, s.total_supplycost ASC) AS rank
    FROM 
        RankedSuppliers s
)
SELECT 
    SM.s_suppkey,
    SM.s_name,
    SM.full_address,
    SM.s_phone,
    SM.part_count,
    SM.total_supplycost
FROM 
    SupplierMetrics SM
WHERE 
    SM.rank <= 5
ORDER BY 
    SM.total_supplycost DESC;
