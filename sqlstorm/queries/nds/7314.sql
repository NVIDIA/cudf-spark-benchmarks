
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY ws.ws_net_profit DESC) as profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
TopPerformers AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_order_number,
        sd.ws_sales_price,
        sd.ws_net_paid,
        sd.ws_net_profit,
        sd.cd_gender,
        sd.cd_marital_status,
        sd.cd_education_status
    FROM 
        SalesData sd
    WHERE 
        sd.profit_rank <= 10
)
SELECT 
    COUNT(*) AS Total_Top_Profitable_Sales,
    AVG(tp.ws_net_profit) AS Avg_Net_Profit,
    SUM(tp.ws_sales_price) AS Total_Sales_Revenue,
    tp.cd_gender,
    tp.cd_marital_status,
    tp.cd_education_status
FROM 
    TopPerformers tp
GROUP BY 
    tp.cd_gender,
    tp.cd_marital_status,
    tp.cd_education_status
ORDER BY 
    Total_Sales_Revenue DESC;
