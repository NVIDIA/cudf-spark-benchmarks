
SELECT 
    COUNT(DISTINCT c.c_customer_sk) AS Total_Customers,
    AVG(i.i_current_price) AS Average_Item_Price,
    SUM(ws.ws_net_profit) AS Total_Net_Profit
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
    AND i.i_current_price > 0
GROUP BY 
    c.c_current_cdemo_sk;
