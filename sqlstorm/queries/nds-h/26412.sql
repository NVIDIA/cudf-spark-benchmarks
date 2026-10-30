
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        COUNT(ps.ps_partkey) AS part_count, 
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name
),
SupplierRank AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.nation_name, 
        s.part_count, 
        s.total_supplycost,
        RANK() OVER (PARTITION BY s.nation_name ORDER BY s.total_supplycost DESC) AS rank
    FROM 
        RankedSuppliers s
)
SELECT 
    sr.s_name, 
    sr.nation_name, 
    sr.part_count, 
    sr.total_supplycost,
    CONCAT('Supplier: ', sr.s_name, ' | Nation: ', sr.nation_name, ' | Parts Count: ', sr.part_count, ' | Total Supply Cost: $', CAST(sr.total_supplycost AS varchar(20))) AS formatted_info
FROM 
    SupplierRank sr
WHERE 
    sr.rank <= 5
ORDER BY 
    sr.nation_name, sr.total_supplycost DESC;
