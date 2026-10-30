WITH Part_Supplier_Info AS (
    SELECT 
        p.p_name,
        s.s_name AS supplier_name,
        CONCAT(s.s_address, ', ', n.n_name) AS supplier_location,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > ps.ps_supplycost THEN 'Profit Opportunity' 
            ELSE 'No Profit Opportunity' 
        END AS opportunity_status
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    p_name,
    supplier_name,
    supplier_location,
    ps_availqty,
    ps_supplycost,
    p_retailprice,
    opportunity_status,
    ROUND((p_retailprice - ps_supplycost) / p_retailprice * 100, 2) AS profit_margin_percentage
FROM 
    Part_Supplier_Info
WHERE 
    opportunity_status = 'Profit Opportunity'
ORDER BY 
    profit_margin_percentage DESC
LIMIT 10;
