WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopSuppliers AS (
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
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        cu.c_name,
        co.order_count,
        co.total_spent,
        su.s_name AS top_supplier,
        su.total_cost
    FROM 
        CustomerOrderSummary co
    JOIN 
        customer cu ON co.c_custkey = cu.c_custkey
    LEFT JOIN 
        TopSuppliers su ON su.total_cost = (SELECT MAX(total_cost) FROM TopSuppliers)
)

SELECT 
    fr.c_name AS Customer_Name,
    fr.order_count AS Number_of_Orders,
    fr.total_spent AS Total_Spent,
    fr.top_supplier AS Top_Supplier,
    fr.total_cost AS Top_Supplier_Total_Cost
FROM 
    FinalReport fr
WHERE 
    fr.order_count > 5
ORDER BY 
    fr.total_spent DESC;
