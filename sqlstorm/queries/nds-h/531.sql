
WITH RegionAggregates AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FrequentCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank,
        co.total_spent
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > 10000
)
SELECT 
    rga.r_name,
    rga.supplier_count,
    rga.total_supply_value,
    top.c_name AS top_customer,
    top.total_spent
FROM 
    RegionAggregates rga
FULL OUTER JOIN 
    (SELECT 
        fc.c_name,
        co.total_spent
     FROM 
        FrequentCustomers fc
     JOIN 
        CustomerOrders co ON fc.c_custkey = co.c_custkey
     WHERE 
        fc.rank = 1) AS top ON TRUE
WHERE 
    rga.total_supply_value IS NOT NULL OR top.total_spent IS NOT NULL
ORDER BY 
    rga.r_name, top.total_spent DESC;
