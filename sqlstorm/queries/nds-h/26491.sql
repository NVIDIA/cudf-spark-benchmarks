
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        SUBSTR(p.p_comment, 1, 10) AS short_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size > 10 AND 
        p.p_retailprice < 100.00
)
SELECT 
    rs.nation AS Supplier_Nation,
    COUNT(DISTINCT rs.s_suppkey) AS Supplier_Count,
    COUNT(DISTINCT fp.p_partkey) AS Relevant_Parts_Count,
    SUM(fp.p_retailprice) AS Total_Retail_Price,
    AVG(fp.ps_supplycost) AS Average_Supply_Cost
FROM 
    RankedSuppliers rs
JOIN 
    FilteredParts fp ON rs.rnk = 1
GROUP BY 
    rs.nation
ORDER BY 
    Supplier_Count DESC, Total_Retail_Price DESC;
