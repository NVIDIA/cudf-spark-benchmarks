
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), HighSpenders AS (
    SELECT 
        c.c_custkey AS custkey,
        c.c_name,
        c.total_spent,
        c.order_count
    FROM 
        CustomerOrders c
    WHERE 
        c.order_count > 1 AND c.order_rank <= 10
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    hs.c_name,
    hs.total_spent,
    hs.order_count,
    ss.total_supply_cost,
    ss.part_count,
    CASE 
        WHEN ss.total_supply_cost IS NULL THEN 'No Supply Data'
        ELSE 'Supply Data Available'
    END AS supply_data_status
FROM 
    HighSpenders hs
LEFT JOIN 
    SupplierStats ss ON hs.custkey = ss.s_suppkey
WHERE 
    hs.total_spent > 5000
ORDER BY 
    hs.total_spent DESC
LIMIT 20;
