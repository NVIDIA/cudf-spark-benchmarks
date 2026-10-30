WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        i.i_current_price > 10
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
        AND ws.ws_sold_date_sk BETWEEN 2458489 AND 2458520  
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk, 
        SUM(sd.total_profit) AS total_profit
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_item_sk
    ORDER BY 
        total_profit DESC
    LIMIT 5  
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    tsi.total_profit
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
ORDER BY 
    tsi.total_profit DESC;