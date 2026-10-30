
WITH ranked_sales AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        i.i_product_name,
        i.i_brand,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk, i.i_product_name, i.i_brand
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ca.ca_state, 
    SUM(rs.total_quantity) AS total_sold,
    SUM(rs.total_sales) AS total_revenue,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.max_purchase_estimate
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    ranked_sales rs ON c.c_customer_sk = rs.ws_item_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    rs.sales_rank <= 10 
GROUP BY 
    ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.max_purchase_estimate
ORDER BY 
    total_revenue DESC;
