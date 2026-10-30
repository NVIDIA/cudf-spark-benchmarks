
WITH Ranked_Sales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
Top_Sellers AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        SUM(sales.ws_quantity) AS total_quantity,
        SUM(sales.ws_net_paid) AS total_revenue
    FROM 
        Ranked_Sales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rank = 1
    GROUP BY 
        item.i_item_id, item.i_product_name
),
Demographic_Metrics AS (
    SELECT 
        demographics.cd_gender,
        COUNT(DISTINCT customer.c_customer_sk) AS num_customers,
        SUM(sales.total_quantity) AS total_quantity_sold,
        SUM(sales.total_revenue) AS total_revenue_generated
    FROM 
        Top_Sellers sales
    JOIN 
        customer customer ON customer.c_customer_sk IN (
            SELECT 
                ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_id IN (SELECT i_item_id FROM Top_Sellers))
        )
    JOIN 
        customer_demographics demographics ON customer.c_current_cdemo_sk = demographics.cd_demo_sk
    GROUP BY 
        demographics.cd_gender
)
SELECT 
    dm.cd_gender,
    dm.num_customers,
    dm.total_quantity_sold,
    dm.total_revenue_generated,
    ROUND(dm.total_revenue_generated / NULLIF(dm.total_quantity_sold, 0), 2) AS avg_revenue_per_item
FROM 
    Demographic_Metrics dm
ORDER BY 
    dm.total_revenue_generated DESC;
