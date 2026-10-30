WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COUNT(DISTINCT ps.ps_supplycost) AS unique_costs,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
)
SELECT 
    n.n_name AS nation,
    COUNT(rs.s_suppkey) AS supplier_count,
    SUM(rs.unique_costs) AS total_unique_costs,
    AVG(rs.s_acctbal) AS avg_account_balance
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.rank = 1
GROUP BY 
    n.n_name
HAVING 
    COUNT(rs.s_suppkey) > 5
ORDER BY 
    total_unique_costs DESC;
