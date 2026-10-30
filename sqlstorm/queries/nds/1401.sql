
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS num_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_salutation,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStats AS (
    SELECT 
        cr.sr_customer_sk AS customer_sk,
        cr.total_returns,
        sd.total_profit,
        sd.total_orders,
        cd.c_salutation,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cr.sr_customer_sk ORDER BY cr.total_returns DESC) AS rank
    FROM 
        CustomerReturns cr
    JOIN 
        SalesData sd ON cr.sr_customer_sk = sd.customer_sk
    JOIN 
        CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
)
SELECT 
    r.customer_sk,
    r.c_salutation,
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_profit, 0) AS total_profit,
    COALESCE(r.total_orders, 0) AS total_orders,
    CASE 
        WHEN r.total_orders = 0 THEN 0 
        ELSE ROUND(r.total_profit / r.total_orders, 2) 
    END AS avg_profit_per_order
FROM 
    ReturnStats r
WHERE 
    r.rank <= 10
ORDER BY 
    r.total_returns DESC;
