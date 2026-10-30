
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_sales_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cr.total_returns, 0) AS returns_count,
        COALESCE(cr.total_return_amount, 0) AS returns_amount,
        COALESCE(sd.total_net_profit, 0) AS net_profit,
        COALESCE(sd.total_sales_quantity, 0) AS sales_quantity,
        COALESCE(sd.total_orders, 0) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cinfo.c_customer_sk,
    cinfo.c_first_name,
    cinfo.c_last_name,
    cinfo.cd_gender,
    cinfo.cd_marital_status,
    cinfo.cd_purchase_estimate,
    cinfo.returns_count,
    cinfo.returns_amount,
    cinfo.net_profit,
    cinfo.sales_quantity,
    cinfo.order_count,
    CASE 
        WHEN first_time_info.is_first_time_customer = 1 THEN 'First Time'
        ELSE 'Returning'
    END AS customer_type,
    ROW_NUMBER() OVER (PARTITION BY cinfo.cd_gender ORDER BY cinfo.net_profit DESC) AS rank_by_profit
FROM 
    (SELECT c.c_customer_sk, 
            c.c_first_name, 
            c.c_last_name, 
            cd.cd_gender, 
            cd.cd_marital_status, 
            cd.cd_purchase_estimate,
            CASE 
                WHEN MIN(d.d_date_sk) IS NULL THEN 1 
                ELSE 0 
            END AS is_first_time_customer
     FROM customer c
     LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
     LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
     GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
    ) AS first_time_info
JOIN CustomerInfo cinfo ON first_time_info.c_customer_sk = cinfo.c_customer_sk
WHERE 
    cinfo.returns_amount > 0 OR cinfo.net_profit > 1000
ORDER BY 
    cinfo.net_profit DESC, 
    cinfo.sales_quantity DESC;
