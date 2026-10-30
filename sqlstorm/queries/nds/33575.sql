
WITH  sales_by_item AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
customer_summary AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        demographics.cd_gender,
        SUM(web_sales.ws_net_paid) AS total_sales_web,
        SUM(store_sales.ss_net_paid) AS total_sales_store,
        COUNT(DISTINCT web_sales.ws_order_number) AS total_orders_web,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS total_orders_store
    FROM 
        customer
    LEFT JOIN 
        customer_demographics AS demographics ON customer.c_current_cdemo_sk = demographics.cd_demo_sk
    LEFT JOIN 
        web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
    GROUP BY 
        customer.c_customer_sk, customer.c_first_name, customer.c_last_name, demographics.cd_gender
), 
sales_ranked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales_web,
        cs.total_sales_store,
        cs.total_orders_web,
        cs.total_orders_store,
        RANK() OVER (ORDER BY (cs.total_sales_web + cs.total_sales_store) DESC) as overall_rank
    FROM 
        customer_summary AS cs
)
SELECT 
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_sales_web,
    sr.total_sales_store,
    sr.total_orders_web,
    sr.total_orders_store,
    CASE 
        WHEN sr.total_sales_web IS NULL AND sr.total_sales_store IS NULL THEN 'No Sales'
        WHEN sr.total_sales_web > sr.total_sales_store THEN 'Web'
        WHEN sr.total_sales_store > sr.total_sales_web THEN 'Store'
        ELSE 'Equal Sales'
    END AS preferred_channel,
    ia.ib_income_band_sk,
    ia.ib_lower_bound,
    ia.ib_upper_bound
FROM 
    sales_ranked AS sr
LEFT JOIN 
    household_demographics AS hd ON sr.c_customer_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band AS ia ON hd.hd_income_band_sk = ia.ib_income_band_sk
WHERE 
    (sr.total_sales_web + sr.total_sales_store) > 1000
    AND (sr.total_orders_web > 5 OR sr.total_orders_store > 5);
