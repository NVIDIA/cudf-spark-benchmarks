
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS Total_Net_Profit,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        AVG(ws.ws_net_paid) AS Avg_Net_Paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
HighProfitCustomers AS (
    SELECT 
        c.c_customer_id AS CustomerID,
        c.Total_Net_Profit,
        c.Total_Orders,
        c.Avg_Net_Paid
    FROM 
        CustomerSales c
    WHERE 
        c.Total_Net_Profit > (SELECT AVG(Total_Net_Profit) FROM CustomerSales)
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS Total_Quantity_Sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        Total_Quantity_Sold DESC
    LIMIT 5
)
SELECT 
    hpc.CustomerID,
    hpc.Total_Net_Profit,
    hpc.Total_Orders,
    hpc.Avg_Net_Paid,
    tp.i_item_id,
    tp.Total_Quantity_Sold
FROM 
    HighProfitCustomers hpc
JOIN 
    TopProducts tp ON tp.Total_Quantity_Sold > 50
ORDER BY 
    hpc.Total_Net_Profit DESC, tp.Total_Quantity_Sold DESC;
