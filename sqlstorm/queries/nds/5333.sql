
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 7300
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales,
        SUM(total_profit) AS total_profit
    FROM 
        SalesData
    GROUP BY 
        ws_item_sk
    ORDER BY 
        total_sales DESC
    LIMIT 10
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ts.total_sales) AS total_sales,
        SUM(ts.total_profit) AS total_profit
    FROM 
        TopItems ti
    JOIN 
        web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    JOIN 
        SalesData ts ON ws.ws_sold_date_sk = ts.ws_sold_date_sk AND ws.ws_item_sk = ts.ws_item_sk
    GROUP BY 
        cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.total_profit,
    CASE 
        WHEN cs.total_sales > 100000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    SalesSummary cs
ORDER BY 
    cs.total_sales DESC;
