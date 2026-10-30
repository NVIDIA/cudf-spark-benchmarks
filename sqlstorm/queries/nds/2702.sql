WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        COALESCE(ws.ws_net_paid_inc_tax, 0) AS net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
),
recent_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.net_paid_inc_tax) AS total_net_paid
    FROM
        sales_data sd
    WHERE 
        sd.rn <= 5
    GROUP BY 
        sd.ws_item_sk
),
customer_details AS (
    SELECT 
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year >= 1970
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(NULLIF(i.i_current_price, 0), 1) AS adjusted_price
    FROM 
        item i
)
SELECT 
    ci.ca_city,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(rs.total_quantity) AS total_items_sold,
    SUM(rs.total_net_paid) AS total_revenue,
    AVG(ii.adjusted_price) AS avg_item_price,
    SUM(CASE WHEN ci.cd_gender = 'F' THEN rs.total_net_paid ELSE 0 END) AS female_revenue,
    SUM(CASE WHEN ci.cd_gender = 'M' THEN rs.total_net_paid ELSE 0 END) AS male_revenue
FROM 
    customer_details ci
LEFT JOIN 
    recent_sales rs ON ci.cd_purchase_estimate = rs.ws_item_sk 
JOIN 
    item_info ii ON rs.ws_item_sk = ii.i_item_sk
GROUP BY 
    ci.ca_city, ci.cd_gender, ci.cd_marital_status
ORDER BY 
    total_revenue DESC 
LIMIT 10;