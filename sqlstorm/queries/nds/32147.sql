
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), sales_analysis AS (
    SELECT 
        a.ws_sold_date_sk,
        a.ws_item_sk,
        a.total_quantity,
        a.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY a.ws_item_sk ORDER BY a.total_net_profit DESC) AS rn,
        d.d_date AS sale_date,
        i.i_item_desc,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Price Not Available'
            ELSE CONCAT('$', ROUND(i.i_current_price, 2))
        END AS formatted_price,
        COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_customer,
        c.c_birth_month,
        c.c_birth_year
    FROM 
        sales_data a
    JOIN 
        item i ON a.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        customer c ON a.ws_item_sk = c.c_customer_sk
    JOIN 
        date_dim d ON a.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    sale_date,
    i_item_desc,
    total_quantity AS quantity_sold,
    total_net_profit,
    formatted_price,
    preferred_customer,
    COUNT(*) OVER (PARTITION BY c_birth_month, c_birth_year) AS customer_count_by_date_of_birth
FROM 
    sales_analysis 
WHERE 
    rn <= 5
ORDER BY 
    sale_date, 
    total_net_profit DESC;
