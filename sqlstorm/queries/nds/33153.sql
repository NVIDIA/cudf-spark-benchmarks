
WITH  CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
PromotionImpact AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_coupon_amt) AS total_coupons_saved
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
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
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        COALESCE(cr.total_returned_quantity, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_value,
        pi.total_profit,
        pi.total_orders,
        pi.total_coupons_saved
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        PromotionImpact pi ON c.c_customer_sk = pi.ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    c.ca_state,
    c.total_returns,
    c.total_returned_value,
    c.total_profit,
    c.total_orders,
    c.total_coupons_saved,
    CASE 
        WHEN c.total_returned_value > 500 THEN 'High Return'
        WHEN c.total_returned_value BETWEEN 100 AND 500 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    CustomerDetails c
WHERE
    (c.total_orders IS NULL OR c.total_orders > 10) AND
    (c.total_profit > 1000 OR c.total_returns > 5)
ORDER BY 
    c.total_profit DESC
LIMIT 100;
