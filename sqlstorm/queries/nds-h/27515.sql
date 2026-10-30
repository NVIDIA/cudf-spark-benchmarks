WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rank 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal 
    FROM 
        RankedSuppliers s 
    WHERE 
        rank <= 5
)
SELECT 
    r.r_name AS region_name, 
    COUNT(DISTINCT fs.s_suppkey) AS supplier_count, 
    AVG(fs.s_acctbal) AS average_account_balance 
FROM 
    region r 
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    FilteredSuppliers fs ON s.s_suppkey = fs.s_suppkey
GROUP BY 
    r.r_name 
ORDER BY 
    average_account_balance DESC;
