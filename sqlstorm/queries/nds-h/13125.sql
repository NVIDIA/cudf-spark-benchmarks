WITH PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.total_avail_qty,
    p.total_supply_cost,
    RANK() OVER (ORDER BY p.total_supply_cost DESC) AS supply_cost_rank
FROM 
    PartSupplierStats p
ORDER BY 
    p.total_avail_qty DESC 
LIMIT 100;
