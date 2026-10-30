
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank <= 10
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender IS NULL THEN 'Not Specified' 
            ELSE cd.cd_gender 
        END AS gender,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COUNT(DISTINCT s.ss_ticket_number) AS total_tickets
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_purchase_estimate
)
SELECT 
    cca.ca_city,
    cca.ca_state,
    SUM(ts.total_quantity) AS quantity_sold,
    SUM(ts.total_sales) AS revenue,
    COUNT(DISTINCT ca.c_customer_sk) AS unique_customers
FROM 
    top_sales ts
JOIN 
    customer_analysis ca ON ca.c_customer_sk = ts.ws_item_sk
JOIN 
    customer_address cca ON ca.c_customer_sk = cca.ca_address_sk
WHERE 
    (cca.ca_state = 'CA' OR cca.ca_state = 'NY')
    AND ts.total_sales > 0
GROUP BY 
    cca.ca_city, cca.ca_state
ORDER BY 
    revenue DESC
LIMIT 20;
