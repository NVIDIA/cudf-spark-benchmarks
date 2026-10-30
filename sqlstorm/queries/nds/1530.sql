
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount,
        AVG(ws_list_price) AS avg_item_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    SUM(COALESCE(cr.total_returned_quantity, 0)) AS total_returned_quantity,
    SUM(COALESCE(ws.total_orders, 0)) AS total_orders,
    SUM(COALESCE(ws.total_sales_amount, 0)) AS total_sales_amount,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    WebSalesSummary ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    cd.cd_marital_status = 'S' AND 
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL) 
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales_amount DESC
LIMIT 50;
