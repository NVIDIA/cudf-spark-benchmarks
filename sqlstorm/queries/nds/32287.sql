
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_name IS NOT NULL AND 
        c.c_last_name IS NOT NULL
), top_sales AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        SUM(cs.ws_sales_price) AS total_sales
    FROM 
        customer_sales cs
    WHERE 
        cs.sale_rank <= 5
    GROUP BY 
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name
), avg_income AS (
    SELECT 
        hd.hd_demo_sk, 
        AVG(NULLIF(hd.hd_income_band_sk, -1)) AS avg_income_band
    FROM 
        household_demographics hd
    GROUP BY 
        hd.hd_demo_sk
)
SELECT 
    t.customer_name, 
    t.total_sales, 
    COALESCE(ai.avg_income_band, 0) AS avg_income_band
FROM 
    (SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name, 
        ts.total_sales
     FROM 
        top_sales ts
     JOIN 
        customer c ON ts.c_customer_sk = c.c_customer_sk) AS t
LEFT JOIN 
    avg_income ai ON ai.hd_demo_sk = (SELECT cd.cd_demo_sk 
                                       FROM customer_demographics cd 
                                       WHERE cd.cd_purchase_estimate > 1000 
                                       ORDER BY cd.cd_demo_sk ASC LIMIT 1)
WHERE 
    t.total_sales > (SELECT AVG(total_sales) FROM top_sales) 
ORDER BY 
    t.total_sales DESC
LIMIT 10;
