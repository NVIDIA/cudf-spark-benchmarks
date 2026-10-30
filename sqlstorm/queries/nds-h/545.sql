WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.rn = 1
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalReport AS (
    SELECT 
        c.c_name AS Customer_Name,
        c.total_spent AS Customer_Total_Spent,
        s.s_name AS Supplier_Name,
        s.total_cost AS Supplier_Total_Cost,
        CASE 
            WHEN c.total_spent IS NULL THEN 'No Orders'
            WHEN s.total_cost IS NULL THEN 'No Supply Cost'
            ELSE 'Active'
        END AS Status
    FROM 
        CustomerOrderSummary c
    FULL OUTER JOIN 
        SupplierPartDetails s ON c.c_custkey = s.s_suppkey
)
SELECT 
    *,
    COALESCE(Customer_Total_Spent, 0) - COALESCE(Supplier_Total_Cost, 0) AS Profit_Comparison,
    CONCAT('Summary for ', COALESCE(Customer_Name, 'N/A'), ' and ', COALESCE(Supplier_Name, 'N/A')) AS Summary_Text
FROM 
    FinalReport
WHERE 
    Status <> 'No Orders'
    OR Status <> 'No Supply Cost'
ORDER BY 
    Profit_Comparison DESC;
