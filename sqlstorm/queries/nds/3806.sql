
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_web_returns,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_store_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_refunded_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), 
sales_summary AS (
    SELECT 
        ci.gender,
        ci.marital_status,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
        SUM(CASE WHEN rs.sale_rank = 1 THEN rs.ws_sales_price ELSE 0 END) AS last_order_amount
    FROM 
        customer_info ci
    JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_order_number
    GROUP BY 
        ci.gender, ci.marital_status
)
SELECT 
    ss.gender,
    ss.marital_status,
    ss.customer_count,
    cntre.total_web_returns,
    cntre.total_store_returns,
    CASE 
        WHEN ss.last_order_amount > 100 THEN 'High Value'
        ELSE 'Regular Value'
    END AS value_category
FROM 
    sales_summary ss
JOIN 
    customer_info cntre ON ss.gender = cntre.gender AND ss.marital_status = cntre.marital_status
WHERE 
    ss.customer_count > 5
ORDER BY 
    ss.customer_count DESC, 
    value_category;
