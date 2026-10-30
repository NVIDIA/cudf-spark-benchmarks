WITH SupplierDetails AS (
    SELECT 
        CONCAT(s.s_name, ' from ', s.s_address, ' - ', s.s_phone) AS Supplier_Info,
        SUBSTRING(s.s_comment, 1, 100) AS Short_Comment,
        r.r_name AS Region_Name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopParts AS (
    SELECT 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_availqty) AS Total_Availability
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, p.p_brand
    ORDER BY 
        Total_Availability DESC
    LIMIT 10
)
SELECT 
    td.Supplier_Info,
    td.Short_Comment,
    tp.p_name AS Top_Part_Name,
    tp.p_brand AS Top_Part_Brand,
    tp.Total_Availability
FROM 
    SupplierDetails td
JOIN 
    TopParts tp ON td.Region_Name = 'ASIA'
WHERE 
    td.Short_Comment LIKE '%urgent%'
ORDER BY 
    tp.Total_Availability DESC;
