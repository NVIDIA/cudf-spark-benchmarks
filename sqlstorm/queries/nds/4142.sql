
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 1000 AND ws_sold_date_sk < 2000
    GROUP BY 
        ws_bill_customer_sk
), 
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
), 
filtered_sales AS (
    SELECT 
        ss.ws_bill_customer_sk,
        ss.total_sales,
        ss.avg_net_profit,
        ss.order_count,
        CASE 
            WHEN cs.cs_item_sk IS NOT NULL THEN 'Catalog' 
            ELSE 'Non-Catalog' 
        END AS sales_type
    FROM 
        sales_summary ss
    LEFT JOIN 
        catalog_sales cs ON ss.ws_bill_customer_sk = cs.cs_bill_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_marital_status,
    cd.cd_gender,
    fs.total_sales,
    fs.avg_net_profit,
    fs.order_count,
    fs.sales_type,
    COALESCE(fs.total_sales, 0) AS total_sales_non_null,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY fs.total_sales DESC) AS sales_rank
FROM 
    customer_details cd
LEFT JOIN 
    filtered_sales fs ON cd.c_customer_sk = fs.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F' 
    AND fs.total_sales > 1000
ORDER BY 
    total_sales DESC;
