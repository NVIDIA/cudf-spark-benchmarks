
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS acctbal_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        COUNT(DISTINCT rs.s_suppkey) AS total_suppliers,
        SUM(rs.part_count) AS total_parts,
        AVG(rs.s_acctbal) AS avg_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.acctbal_rank <= 10
    GROUP BY 
        r.r_name, ns.n_name
)
SELECT 
    region_name, 
    nation_name, 
    total_suppliers, 
    total_parts, 
    avg_acctbal,
    CONCAT('Region: ', region_name, ', Nation: ', nation_name, ', Suppliers: ', total_suppliers, ', Parts: ', total_parts, ', Avg. Account Balance: ', CAST(avg_acctbal AS VARCHAR(20))) AS summary
FROM 
    HighValueSuppliers
ORDER BY 
    avg_acctbal DESC;
