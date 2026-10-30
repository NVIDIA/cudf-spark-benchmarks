
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        CD_Promotion_Count.Promotion_Count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS Sales_Rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            ws_order_number,
            COUNT(DISTINCT ws_item_sk) AS Promotion_Count
        FROM 
            web_sales
        WHERE 
            ws_sales_price < 50
        GROUP BY 
            ws_order_number
    ) CD_Promotion_Count ON ws.ws_order_number = CD_Promotion_Count.ws_order_number
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
InventoryData AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS Total_Quantity_On_Hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    sds.ws_order_number,
    COUNT(sds.ws_item_sk) AS Item_Count,
    SUM(sds.ws_net_paid) AS Total_Net_Paid,
    SUM(sds.ws_quantity) AS Total_Quantity_Sold,
    MAX(sds.ws_sales_price) AS Max_Sales_Price,
    COALESCE(SUM(id.Total_Quantity_On_Hand), 0) AS Stock_Availability,
    MIN(sds.Sales_Rank) AS Best_Selling_Item_Rank
FROM 
    SalesData sds
LEFT JOIN 
    InventoryData id ON sds.ws_item_sk = id.inv_item_sk
WHERE 
    sds.cd_gender = 'F'
    AND sds.cd_marital_status = 'M'
GROUP BY 
    sds.ws_order_number
HAVING 
    COUNT(sds.ws_item_sk) > 1
ORDER BY 
    Total_Net_Paid DESC;
