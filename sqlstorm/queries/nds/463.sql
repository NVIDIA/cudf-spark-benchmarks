
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS Sales_Rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_id
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        AVG(ws.ws_net_profit) AS Avg_Profit
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_id,
    cs.Total_Sales,
    CASE 
        WHEN ws.Total_Orders IS NULL THEN 'No Orders'
        ELSE CAST(ws.Total_Orders AS STRING)
    END AS Total_Orders,
    COALESCE(ws.Avg_Profit, 0) AS Avg_Profit,
    CASE 
        WHEN cs.Sales_Rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS Customer_Type
FROM 
    CustomerSales cs
FULL OUTER JOIN 
    WarehouseStats ws ON cs.Total_Sales IS NOT NULL AND ws.Total_Orders IS NOT NULL
WHERE 
    cs.Total_Sales > 1000 OR ws.Total_Orders > 5
ORDER BY 
    cs.Total_Sales DESC, ws.Total_Orders DESC;
