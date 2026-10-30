WITH PartSupplierInfo AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT(s.s_name, ' from ', p.p_name, ' with retail price ', p.p_retailprice) AS supplier_part_info,
        p.p_retailprice,
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
),
HighDemandSuppliers AS (
    SELECT 
        p_name,
        s_name,
        supplier_part_info,
        RANK() OVER (PARTITION BY p_name ORDER BY ps_availqty DESC) AS rank_avail
    FROM 
        PartSupplierInfo
)
SELECT 
    p_name,
    s_name,
    supplier_part_info
FROM 
    HighDemandSuppliers
WHERE 
    rank_avail = 1
ORDER BY 
    p_name, s_name;
