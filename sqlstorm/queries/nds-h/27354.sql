
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank,
        p.p_type
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
SupplierComments AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.p_type,
        CONCAT('Supplier ', rs.s_name, ' specializes in ', rs.p_type, ' parts and has an account balance of ', CAST(rs.s_acctbal AS STRING) ) AS detailed_comment
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    sc.s_suppkey,
    sc.s_name,
    sc.p_type,
    STRING_AGG(sc.detailed_comment, ' | ') AS suppliers_info
FROM 
    SupplierComments sc
GROUP BY 
    sc.s_suppkey,
    sc.s_name,
    sc.p_type
ORDER BY 
    sc.p_type;
