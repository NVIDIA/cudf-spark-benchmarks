
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT p.p_partkey) AS unique_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS region_rank,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        r.r_name, 
        rs.s_name, 
        rs.total_available_qty, 
        rs.unique_parts 
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.region_rank <= 3
),
AggregatedResults AS (
    SELECT 
        r_name, 
        SUM(total_available_qty) AS total_qty, 
        COUNT(s_name) AS supplier_count,
        AVG(unique_parts) AS avg_unique_parts
    FROM 
        HighValueSuppliers
    GROUP BY 
        r_name
)
SELECT 
    r_name, 
    total_qty, 
    supplier_count, 
    avg_unique_parts 
FROM 
    AggregatedResults 
ORDER BY 
    total_qty DESC
LIMIT 10;
