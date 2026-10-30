WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
item_data AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_brand,
        i_current_price
    FROM 
        item
    WHERE 
        i_rec_start_date <= cast('2002-10-01' as date) AND (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ranking_data AS (
    SELECT 
        sd.ws_item_sk,
        id.i_item_desc,
        id.i_brand,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (PARTITION BY id.i_brand ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
    INNER JOIN 
        item_data id ON sd.ws_item_sk = id.i_item_sk
    WHERE 
        sd.total_quantity > 100 AND sd.total_sales > 1000
)
SELECT 
    rd.ws_item_sk,
    rd.i_item_desc,
    rd.i_brand,
    rd.total_quantity,
    rd.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate
FROM 
    ranking_data rd
JOIN 
    customer_data cd ON cd.cd_purchase_estimate BETWEEN 500 AND 1000
WHERE 
    rd.sales_rank <= 5
ORDER BY 
    rd.i_brand, rd.total_sales DESC;