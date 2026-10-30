WITH part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        p.p_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_comment
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        c.c_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_comment
)
SELECT 
    pd.p_name AS PartName,
    pd.p_brand AS Brand,
    co.c_name AS CustomerName,
    co.total_orders AS TotalOrders,
    co.total_spent AS TotalSpent,
    pd.total_available_qty AS AvailableQty,
    pd.avg_supply_cost AS AvgSupplyCost,
    CONCAT(pd.p_comment, ' | ', co.c_comment) AS CombinedComments
FROM 
    part_details pd
JOIN 
    lineitem l ON pd.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer_orders co ON o.o_custkey = co.c_custkey
WHERE 
    pd.p_size > 20 AND 
    co.total_spent > 500
ORDER BY 
    pd.p_name, co.total_spent DESC
LIMIT 100;
