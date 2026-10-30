
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_state
), ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender, ca_state ORDER BY total_sales DESC) AS state_gender_rank
    FROM 
        sales_data
)
SELECT 
    rs.ca_state,
    rs.cd_gender,
    COUNT(DISTINCT rs.ws_item_sk) AS unique_items,
    AVG(rs.total_sales) AS avg_sales,
    SUM(rs.total_quantity) AS total_quantity_sold
FROM 
    ranked_sales rs
WHERE 
    rs.state_gender_rank <= 5
GROUP BY 
    rs.ca_state, rs.cd_gender
ORDER BY 
    rs.ca_state, rs.cd_gender;
