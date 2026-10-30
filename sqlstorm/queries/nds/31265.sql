
WITH  sales_cte AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT MIN(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid_inc_tax) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (
            SELECT MIN(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023
        )
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
), 
order_summary AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(sales.total_quantity) AS total_quantity,
        SUM(sales.total_sales) AS total_sales
    FROM 
        item
    JOIN sales_cte AS sales ON item.i_item_sk = sales.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_product_name
), 
customer_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT customer.c_customer_sk) AS customer_count
    FROM 
        customer_demographics 
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender
)
SELECT 
    os.i_product_name,
    os.total_quantity,
    os.total_sales,
    cs.avg_purchase_estimate,
    cs.customer_count
FROM 
    order_summary AS os
LEFT JOIN customer_summary AS cs ON 
    (os.total_sales > 1000 AND cs.avg_purchase_estimate IS NOT NULL)
WHERE 
    (os.total_quantity > 10 OR cs.customer_count > 5)
ORDER BY 
    os.total_sales DESC
LIMIT 100;
