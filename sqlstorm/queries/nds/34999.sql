
WITH  sales_data AS (
    SELECT 
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM web_sales
    GROUP BY ws_ship_customer_sk, ws_item_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), high_value_sales AS (
    SELECT 
        sd.ws_ship_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(sd.total_profit) AS total_customer_profit
    FROM sales_data sd
    JOIN customer_info ci ON sd.ws_ship_customer_sk = ci.c_customer_sk
    WHERE sd.total_quantity > 5
    GROUP BY sd.ws_ship_customer_sk, ci.c_first_name, ci.c_last_name
), filtered_high_value AS (
    SELECT 
        *,
        CASE 
            WHEN total_customer_profit > 1000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_status
    FROM high_value_sales
), max_sales AS (
    SELECT 
        customer_status,
        MAX(total_customer_profit) AS max_profit
    FROM filtered_high_value
    GROUP BY customer_status
)
SELECT 
    fh.customer_status,
    fh.total_customer_profit,
    fh.c_first_name,
    fh.c_last_name,
    m.max_profit,
    coalesce(m.max_profit - fh.total_customer_profit, 0) AS profit_difference,
    CASE 
        WHEN fh.total_customer_profit > (SELECT AVG(total_customer_profit) FROM filtered_high_value) 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_category
FROM filtered_high_value fh
LEFT JOIN max_sales m ON fh.customer_status = m.customer_status
ORDER BY fh.total_customer_profit DESC;
