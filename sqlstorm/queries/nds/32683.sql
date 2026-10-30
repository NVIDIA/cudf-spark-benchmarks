
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
MaxProfit AS (
    SELECT 
        ws_item_sk, 
        MAX(total_profit) AS max_profit
    FROM 
        SalesCTE
    WHERE 
        rank <= 5
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        d.d_year,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT 
            sr_customer_sk, 
            COUNT(DISTINCT sr_ticket_number) AS return_count, 
            SUM(sr_return_amt_inc_tax) AS total_return_value
         FROM 
            store_returns
         GROUP BY 
            sr_customer_sk) cr ON c.c_customer_sk = cr.sr_customer_sk
    JOIN 
        (SELECT DISTINCT d_year FROM date_dim) d ON d.d_year IS NOT NULL
),
TopCustomerReturns AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.return_count,
        ci.total_return_value,
        mp.max_profit
    FROM 
        CustomerInfo ci
    JOIN 
        MaxProfit mp ON ci.c_customer_sk = mp.ws_item_sk
    WHERE 
        ci.return_count > 0
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.return_count,
    tc.total_return_value,
    tc.max_profit
FROM 
    TopCustomerReturns tc
ORDER BY 
    tc.total_return_value DESC;
