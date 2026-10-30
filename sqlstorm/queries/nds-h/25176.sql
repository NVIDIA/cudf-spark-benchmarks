WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        p.p_name,
        p.p_brand
    FROM 
        RankedSuppliers rs
    JOIN 
        part p ON p.p_partkey = rs.s_suppkey
    WHERE 
        rs.rank <= 5
),
CombinedResults AS (
    SELECT 
        fs.s_name,
        fs.p_name,
        fs.p_brand,
        CONCAT('Supplier: ', fs.s_name, ', Part: ', fs.p_name, ', Brand: ', fs.p_brand) AS combined_info
    FROM 
        FilteredSuppliers fs
)
SELECT 
    combined_info,
    COUNT(*) AS supplier_count
FROM 
    CombinedResults
GROUP BY 
    combined_info
ORDER BY 
    supplier_count DESC;
