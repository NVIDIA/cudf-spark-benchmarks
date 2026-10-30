
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
SalesStats AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS online_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_sales_amount,
        cs.total_profit,
        COALESCE(ss.online_sales_amount, 0) AS online_sales
    FROM 
        CustomerStats cs
    LEFT JOIN 
        SalesStats ss ON cs.c_customer_sk = ss.customer_sk
)
SELECT 
    t.c_customer_sk,
    t.total_sales,
    t.total_sales_amount,
    t.total_profit,
    t.online_sales,
    (t.total_sales_amount + t.online_sales) AS combined_sales_amount
FROM 
    TotalSales t
ORDER BY 
    combined_sales_amount DESC
LIMIT 10;
