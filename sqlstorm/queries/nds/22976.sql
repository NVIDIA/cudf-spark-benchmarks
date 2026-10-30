
WITH  demographic_analysis AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status
),
sales_summary AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_quantity) AS total_sold, 
        SUM(ss_net_paid) AS total_sales_income,
        SUM(ss_ext_tax) AS total_sales_tax
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2451545 AND 2451550 
    GROUP BY 
        ss_item_sk
),
item_enrich AS (
    SELECT 
        i_item_sk, 
        i_product_name, 
        i_current_price, 
        COALESCE(MAX(CASE WHEN ws_ext_sales_price IS NOT NULL THEN ws_ext_sales_price END), 0) AS web_sales_price,
        COALESCE(MAX(CASE WHEN cs_ext_sales_price IS NOT NULL THEN cs_ext_sales_price END), 0) AS catalog_sales_price
    FROM 
        item 
    LEFT JOIN 
        web_sales ON i_item_sk = ws_item_sk
    LEFT JOIN 
        catalog_sales ON i_item_sk = cs_item_sk
    GROUP BY 
        i_item_sk, 
        i_product_name, 
        i_current_price
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    s.total_sold,
    s.total_sales_income,
    i.i_product_name,
    i.i_current_price,
    i.web_sales_price,
    i.catalog_sales_price,
    CASE 
        WHEN s.total_sold IS NULL THEN 0 
        ELSE (s.total_sales_income / NULLIF(s.total_sold, 0)) 
    END AS avg_price_per_item,
    CASE 
        WHEN i.web_sales_price = 0 AND i.catalog_sales_price = 0 THEN 'No Sales Available'
        ELSE 'Sales Available'
    END AS sales_status
FROM 
    demographic_analysis d
LEFT JOIN 
    sales_summary s ON d.cd_demo_sk = s.ss_item_sk
LEFT JOIN 
    item_enrich i ON s.ss_item_sk = i.i_item_sk
WHERE 
    (d.customer_count > 1 OR NULLIF(d.cd_gender, 'F') IS NOT NULL)
ORDER BY 
    d.cd_marital_status DESC, 
    d.cd_gender, 
    sales_status,
    avg_price_per_item DESC
LIMIT 50 OFFSET 5;
