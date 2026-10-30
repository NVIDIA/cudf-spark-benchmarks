
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price >= (SELECT AVG(ws_inner.ws_sales_price) 
                               FROM web_sales ws_inner
                               WHERE ws_inner.ws_sold_date_sk > 0)
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
),
not_returned_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_revenue
    FROM 
        sales_data sd
    LEFT JOIN 
        store_returns sr ON sd.ws_item_sk = sr.sr_item_sk AND sd.ws_order_number = sr.sr_ticket_number
    WHERE 
        sr.sr_ticket_number IS NULL OR sr.sr_ticket_number = -1
    GROUP BY 
        sd.ws_item_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    SUM(nrs.total_quantity) AS total_quantity_sold,
    MAX(nrs.total_revenue) AS max_revenue_per_item,
    AVG(nrs.total_revenue) AS average_revenue_per_item,
    CASE 
        WHEN MAX(nrs.total_revenue) IS NULL THEN 'No Sales'
        WHEN MAX(nrs.total_revenue) > 10000 THEN 'High Roller'
        WHEN MAX(nrs.total_revenue) BETWEEN 5000 AND 10000 THEN 'Moderate Player'
        ELSE 'Occasional Buyer' 
    END AS customer_category
FROM 
    customer_data cd
LEFT JOIN 
    not_returned_sales nrs ON cd.c_customer_sk = nrs.ws_item_sk
WHERE 
    cd.gender_rank = 1
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.cd_gender
HAVING 
    SUM(nrs.total_quantity) > 0
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
