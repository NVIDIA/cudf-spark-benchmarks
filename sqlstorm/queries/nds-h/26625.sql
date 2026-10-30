WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_type LIKE '%metal%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    r.r_name AS Region,
    COUNT(DISTINCT cs.c_custkey) AS CustomerCount,
    SUM(sd.s_acctbal) AS TotalAccountBalance,
    SUM(CASE WHEN rs.rnk = 1 THEN sd.part_count END) AS TopSupplierPartCount
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
JOIN 
    customer cs ON s.s_nationkey = cs.c_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
GROUP BY 
    r.r_name
ORDER BY 
    TotalAccountBalance DESC;
