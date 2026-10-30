
WITH  sales_trends AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_bill_customer_sk IS NOT NULL
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
high_sales AS (
    SELECT 
        ws_item_sk,
        MAX(total_sales) AS max_sales,
        AVG(total_sales) AS avg_sales
    FROM 
        sales_trends
    GROUP BY 
        ws_item_sk
    HAVING MAX(total_sales) > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        (CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other' 
        END) AS gender_label,
        h.hd_income_band_sk,
        ia.ib_lower_bound,
        ia.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_customer_sk = h.hd_demo_sk
    LEFT JOIN 
        income_band ia ON h.hd_income_band_sk = ia.ib_income_band_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.gender_label,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ci.hd_income_band_sk IS NOT NULL
    GROUP BY 
        ci.c_customer_sk, ci.gender_label
)
SELECT 
    tci.gender_label,
    COUNT(tci.c_customer_sk) AS customer_count,
    SUM(hs.max_sales) AS overall_max_sales,
    AVG(tci.total_profit) AS avg_profit
FROM 
    top_customers tci
JOIN 
    high_sales hs ON tci.c_customer_sk IN (
        SELECT DISTINCT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk IN (
            SELECT ws_item_sk 
            FROM sales_trends 
            WHERE total_quantity > 50
        )
    )
GROUP BY 
    tci.gender_label
ORDER BY 
    customer_count DESC
LIMIT 10;
