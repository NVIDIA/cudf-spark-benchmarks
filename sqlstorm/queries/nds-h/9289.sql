WITH  supply_chain AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name AS supplier_name, 
        s.s_acctbal AS supplier_balance, 
        p.p_name AS part_name, 
        p.p_retailprice AS retail_price, 
        ps.ps_availqty AS available_quantity,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), rank_chain AS (
    SELECT 
        part_name, 
        supplier_name, 
        supplier_balance, 
        retail_price, 
        available_quantity,
        rn
    FROM 
        supply_chain
    WHERE 
        rn <= 5
)
SELECT 
    rc.part_name, 
    SUM(rc.available_quantity) AS total_available_quantity,
    COUNT(DISTINCT rc.supplier_name) AS number_of_suppliers,
    MAX(rc.supplier_balance) AS highest_supplier_balance,
    AVG(rc.retail_price) AS avg_retail_price
FROM 
    rank_chain rc
GROUP BY 
    rc.part_name
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
