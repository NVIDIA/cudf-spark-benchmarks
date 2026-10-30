
WITH CTE_CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_spending
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, c.c_nationkey
),
CTE_SupplierPartSupply AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CTE_LineItemStats AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_revenue,
        SUM(l.l_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_item_rank
    FROM
        lineitem l
    WHERE
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY
        l.l_orderkey
)

SELECT
    co.c_name AS Customer_Name,
    co.total_orders AS Total_Orders,
    co.total_spent AS Total_Spent,
    CASE 
        WHEN co.rank_by_spending <= 3 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS Customer_Category,
    ss.s_name AS Supplier_Name,
    ss.total_supply_value AS Supplier_Total_Value,
    li.total_lineitem_revenue AS LineItem_Revenue,
    li.total_quantity AS LineItem_Quantity
FROM
    CTE_CustomerOrders co
LEFT JOIN
    CTE_SupplierPartSupply ss ON co.c_custkey = ss.s_suppkey 
JOIN
    CTE_LineItemStats li ON co.c_custkey = li.l_orderkey 
WHERE
    co.total_spent > (SELECT AVG(total_spent) FROM CTE_CustomerOrders) 
ORDER BY
    co.total_spent DESC,
    ss.total_supply_value DESC;
