WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
SelectedSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal,
        AVG(rs.s_acctbal) AS avg_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey 
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r_name,
    supplier_count,
    total_acctbal,
    avg_acctbal,
    CONCAT(r_name, ' has ', supplier_count, ' suppliers with a total account balance of ', total_acctbal, ' and an average balance of ', avg_acctbal) AS summary
FROM 
    SelectedSuppliers
ORDER BY 
    total_acctbal DESC;