WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_brand,
        p.p_container,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
FilteredSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.s_acctbal,
        r.p_brand,
        r.p_container
    FROM 
        RankedSuppliers r
    WHERE 
        r.rnk <= 3
)
SELECT 
    f.p_brand,
    f.p_container,
    COUNT(*) AS supplier_count,
    SUM(f.s_acctbal) AS total_acctbal,
    AVG(f.s_acctbal) AS avg_acctbal
FROM 
    FilteredSuppliers f
GROUP BY 
    f.p_brand, f.p_container
ORDER BY 
    total_acctbal DESC;
