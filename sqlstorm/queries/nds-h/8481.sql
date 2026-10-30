WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CountryWiseSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(sp.s_suppkey) AS supplier_count,
        SUM(sp.total_available_quantity) AS sum_available_quantity,
        SUM(sp.total_supply_cost) AS sum_supply_cost
    FROM 
        SupplierParts sp
    JOIN 
        nation n ON sp.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    country.nation_name,
    country.supplier_count,
    country.sum_available_quantity,
    country.sum_supply_cost,
    CASE 
        WHEN country.sum_supply_cost > 100000 THEN 'High Value'
        WHEN country.sum_supply_cost BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS cost_category
FROM 
    CountryWiseSuppliers country
WHERE 
    country.supplier_count > 5
ORDER BY 
    country.sum_supply_cost DESC
LIMIT 10;
