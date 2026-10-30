
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnedItems AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        COALESCE(rs.total_profit, 0) AS total_profit,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.total_return_value, 0) AS total_return_value,
        CASE 
            WHEN COALESCE(rs.total_profit, 0) > 1000 THEN 'High Value Customer'
            WHEN COALESCE(rs.total_profit, 0) BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
            ELSE 'Low Value Customer'
        END AS customer_value_category
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN 
        ReturnedItems ri ON cd.c_customer_sk = ri.sr_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_profit,
    f.total_returns,
    f.total_return_value,
    f.customer_value_category
FROM 
    FinalReport f
WHERE 
    f.total_profit > 0 OR f.total_returns > 0
ORDER BY 
    f.customer_value_category DESC, 
    f.total_profit DESC;
