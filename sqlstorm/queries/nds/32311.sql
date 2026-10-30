
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458114 AND 2458115
    GROUP BY 
        ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_ranking AS (
    SELECT 
        si.ws_item_sk,
        si.total_quantity,
        si.total_net_paid,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.ca_city
    FROM 
        sales_summary si
    LEFT JOIN 
        customer_info ci ON si.ws_item_sk = ci.c_customer_sk
    WHERE 
        si.rank <= 10
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.total_net_paid,
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ci.ca_city,
    CASE 
        WHEN s.total_net_paid IS NULL THEN 'No Sales Data'
        WHEN s.total_net_paid > 1000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    sales_ranking s
LEFT JOIN 
    customer_info ci ON s.c_customer_sk = ci.c_customer_sk
ORDER BY 
    s.total_net_paid DESC;
