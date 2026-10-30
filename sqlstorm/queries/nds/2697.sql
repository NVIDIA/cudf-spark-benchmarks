
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
EnhancedCustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(sd.total_sold_quantity, 0) AS total_sold_quantity,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
PerformanceMetrics AS (
    SELECT 
        ec.c_customer_sk,
        ec.c_first_name,
        ec.c_last_name,
        ec.cd_gender,
        ec.cd_marital_status,
        ec.total_returned_quantity,
        ec.total_sold_quantity,
        ec.total_net_profit,
        CASE 
            WHEN ec.total_sold_quantity = 0 THEN 0 
            ELSE (CAST(ec.total_returned_quantity AS decimal) / ec.total_sold_quantity) * 100 
        END AS return_rate,
        ROW_NUMBER() OVER (ORDER BY ec.total_net_profit DESC) AS rank_by_net_profit
    FROM 
        EnhancedCustomerData ec
)
SELECT 
    pm.c_customer_sk,
    pm.c_first_name || ' ' || pm.c_last_name AS full_name,
    pm.cd_gender,
    pm.cd_marital_status,
    pm.total_returned_quantity,
    pm.total_sold_quantity,
    pm.total_net_profit,
    pm.return_rate,
    CASE 
        WHEN pm.rank_by_net_profit <= 10 THEN 'Top 10 Customers' 
        ELSE 'Other Customers' 
    END AS customer_category
FROM 
    PerformanceMetrics pm
WHERE 
    pm.total_net_profit > 1000
    AND (pm.cd_gender = 'F' OR pm.cd_marital_status = 'M')
ORDER BY 
    pm.return_rate DESC, pm.total_net_profit DESC;
