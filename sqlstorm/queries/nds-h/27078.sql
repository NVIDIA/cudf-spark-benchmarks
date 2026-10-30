WITH PartSupplierDetails AS (
    SELECT 
        p.p_name,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY (ps.ps_availqty * ps.ps_supplycost) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_name LIKE '%widget%' AND 
        s.s_acctbal > 1000
),
TopInventories AS (
    SELECT 
        p_name,
        s_name,
        s_acctbal,
        total_value
    FROM 
        PartSupplierDetails
    WHERE 
        rn <= 3
)
SELECT 
    p_name, 
    s_name, 
    s_acctbal, 
    total_value,
    CONCAT(p_name, ' from ', s_name, ' has a total inventory value of ', total_value) AS inventory_info
FROM 
    TopInventories
ORDER BY 
    total_value DESC;
