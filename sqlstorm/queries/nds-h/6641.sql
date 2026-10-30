WITH SupplierPartDetails AS (
    SELECT 
        s.s_name,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
),
TopSuppParts AS (
    SELECT 
        s_name,
        p_name,
        total_available_quantity,
        total_supply_cost,
        RANK() OVER (PARTITION BY s_name ORDER BY total_available_quantity DESC) AS part_rank
    FROM 
        SupplierPartDetails
)
SELECT 
    s_name,
    p_name,
    total_available_quantity,
    total_supply_cost
FROM 
    TopSuppParts
WHERE 
    part_rank <= 3
ORDER BY 
    s_name, total_available_quantity DESC;
