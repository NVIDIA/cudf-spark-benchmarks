
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
WebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_web_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer_demographics 
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
Ranking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(cr.total_returned_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(ws.total_web_profit, 0)) AS total_web_profit,
        RANK() OVER (ORDER BY SUM(COALESCE(ws.total_web_profit, 0)) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year < 1980 
        AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.total_returned_quantity,
    r.total_web_profit,
    CASE 
        WHEN r.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    Ranking r
WHERE 
    r.total_web_profit > (SELECT AVG(total_web_profit) FROM WebSales)
ORDER BY 
    r.total_returned_quantity DESC, r.total_web_profit DESC;
