WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
TopPartSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        rs.s_suppkey, 
        rs.s_name, 
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rn <= 5
    GROUP BY 
        ps.ps_partkey, 
        rs.s_suppkey, 
        rs.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        COALESCE(ps.total_availqty, 0) AS total_availqty
    FROM 
        part p
    LEFT JOIN 
        TopPartSuppliers ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    pd.p_partkey, 
    pd.p_name, 
    pd.p_brand, 
    pd.total_availqty, 
    CONCAT('Supplier: ', ps.s_name, ' - Availability: ', pd.total_availqty) AS supplier_info
FROM 
    PartDetails pd
LEFT JOIN 
    TopPartSuppliers ps ON pd.p_partkey = ps.ps_partkey
ORDER BY 
    pd.total_availqty DESC, 
    pd.p_name;
