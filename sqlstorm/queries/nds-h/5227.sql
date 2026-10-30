
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),

PartAggregation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count,
        AVG(p.p_retailprice) AS avg_retail_price
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)

SELECT 
    os.c_name AS Customer,
    ss.s_name AS Supplier,
    ps.p_name AS Part_Name,
    psa.suppliers_count AS Suppliers_Count,
    psa.avg_retail_price AS Avg_Retail_Price,
    os.total_orders AS Total_Orders,
    os.total_spent AS Total_Spent,
    ss.total_available_qty AS Total_Available_Qty,
    ss.total_supply_cost AS Total_Supply_Cost
FROM 
    CustomerOrderSummary os
JOIN 
    SupplierSummary ss ON os.total_spent > 10000
JOIN 
    PartAggregation psa ON psa.avg_retail_price < 50
JOIN 
    part ps ON psa.p_partkey = ps.p_partkey
WHERE 
    os.total_orders > 5
ORDER BY 
    os.total_spent DESC, ss.total_supply_cost ASC
LIMIT 100;
