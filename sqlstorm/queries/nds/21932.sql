
WITH  avg_income AS (
    SELECT 
        hd_income_band_sk, 
        AVG(ib_upper_bound) AS avg_upper_bound 
    FROM 
        household_demographics 
    JOIN 
        income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk 
    GROUP BY 
        hd_income_band_sk
),
recent_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 1) 
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        a.ca_city,
        a.ca_state,
        (SELECT 
            AVG(total_profit) 
         FROM 
            recent_sales 
         WHERE 
            recent_sales.ws_bill_customer_sk = c.c_customer_sk) AS customer_avg_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics) 
        AND a.ca_state IS NOT NULL
),
final_data AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.customer_avg_profit,
        ci.ca_city,
        ci.ca_state,
        ai.avg_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY ci.ca_state ORDER BY ci.customer_avg_profit DESC) AS rank_within_state 
    FROM 
        customer_info ci
    JOIN 
        avg_income ai ON ci.cd_purchase_estimate < ai.avg_upper_bound
)
SELECT 
    fd.c_customer_sk,
    fd.c_first_name,
    fd.c_last_name,
    fd.cd_gender,
    fd.cd_marital_status,
    fd.customer_avg_profit,
    fd.ca_city,
    fd.ca_state,
    fd.rank_within_state
FROM 
    final_data fd
WHERE 
    fd.rank_within_state <= 5 
    AND (fd.cd_gender = 'F' OR fd.cd_marital_status = 'S') 
ORDER BY 
    fd.ca_state, fd.customer_avg_profit DESC
