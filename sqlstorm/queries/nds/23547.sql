WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        NULLIF(SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk), 0) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date < cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
),
high_value_sales AS (
    SELECT 
        rs.ws_item_sk,
        MAX(rs.ws_sales_price) AS max_sales_price,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM 
        ranked_sales rs
    WHERE 
        rs.price_rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 5
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.order_count,
    hv.max_sales_price,
    hv.avg_sales_price,
    ci.hd_income_band_sk
FROM 
    customer_info ci
JOIN 
    high_value_sales hv ON ci.c_customer_sk IN (
        SELECT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_sales_price > (SELECT AVG(ws_sales_price) FROM ranked_sales)
            AND ws.ws_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE price_rank = 1)
    )
WHERE 
    ci.hd_income_band_sk IS NOT NULL
ORDER BY 
    ci.order_count DESC, 
    hv.avg_sales_price DESC;