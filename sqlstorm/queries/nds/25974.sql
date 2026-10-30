
WITH customer_info AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city AS city,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        COALESCE(cd.cd_dep_college_count, 0) AS college_dependents
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk AS item_sk,
        i.i_item_desc AS item_description,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
sales_ranking AS (
    SELECT 
        item_sk, 
        item_description,
        total_quantity_sold, 
        total_sales_amount,
        order_count,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        item_sales
)
SELECT 
    ci.customer_sk,
    ci.full_name,
    ci.city,
    ci.state,
    ci.gender,
    ci.marital_status,
    si.item_description,
    si.total_quantity_sold,
    si.total_sales_amount,
    si.sales_rank
FROM 
    customer_info ci
JOIN 
    sales_ranking si ON ci.customer_sk % (SELECT COUNT(*) FROM customer_info) = si.sales_rank % (SELECT COUNT(*) FROM sales_ranking)
WHERE 
    ci.city IS NOT NULL 
    AND ci.state IS NOT NULL
ORDER BY 
    si.total_sales_amount DESC,
    ci.full_name ASC
LIMIT 100;
