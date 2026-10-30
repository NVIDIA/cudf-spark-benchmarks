WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        CONCAT(s.s_phone, ' - ', s.s_comment) AS contact_details,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        s.*
    FROM 
        SupplierDetails s
    WHERE 
        s.rn <= 3
),
PartSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(*) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.supplier_count,
    REPLACE(p.p_name, 'part', 'component') AS modified_part_name,
    UPPER(p.p_brand) AS uppercase_brand
FROM 
    PartSuppliers p
ORDER BY 
    p.supplier_count DESC;
