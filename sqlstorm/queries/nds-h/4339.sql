WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
),
PartOrderDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(li.l_quantity) AS total_sold,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_name
)
SELECT 
    cs.c_name AS Customer_Name,
    ss.s_name AS Supplier_Name,
    ps.p_name AS Part_Name,
    ps.total_sold,
    ps.total_revenue,
    ss.total_available_qty,
    ss.avg_supply_cost,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No orders'
        ELSE 'Spent: ' || cs.total_spent 
    END AS Customer_Spending_Info
FROM 
    CustomerOrderStats cs
FULL OUTER JOIN 
SupplierStats ss ON cs.c_custkey = ss.s_suppkey
FULL OUTER JOIN 
PartOrderDetails ps ON ss.s_suppkey = ps.p_partkey
WHERE 
    (ss.total_available_qty > 100 OR ps.total_sold > 50)
    AND (cs.total_orders > 0 OR ss.avg_supply_cost < 20.00)
ORDER BY 
    cs.total_spent DESC NULLS LAST, 
    ps.total_revenue DESC;
