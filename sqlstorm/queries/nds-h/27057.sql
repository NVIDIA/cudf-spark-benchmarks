
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        rs.s_name, 
        rs.TotalSupplyCost,
        CONCAT('Supplier: ', rs.s_name, ' - Total Supply Cost: ', CAST(rs.TotalSupplyCost AS STRING)) AS FormattedOutput
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.Rank <= 5
)
SELECT 
    r_name, 
    STRING_AGG(FormattedOutput, '; ') AS SupplierInfo
FROM 
    TopSuppliers
GROUP BY 
    r_name
ORDER BY 
    r_name;
