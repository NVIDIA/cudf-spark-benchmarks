
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
AggregateSales AS (
    SELECT 
        item.i_item_id,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_count,
        AVG(sd.ws_sales_price) AS avg_sales_price
    FROM 
        SalesData sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.rn = 1
    GROUP BY 
        item.i_item_id
),
TopItems AS (
    SELECT 
        ais.i_item_id,
        ais.total_quantity,
        ais.total_net_paid,
        ais.sales_count,
        ais.avg_sales_price,
        RANK() OVER (ORDER BY ais.total_net_paid DESC) AS sales_rank
    FROM 
        AggregateSales ais
    WHERE 
        ais.total_quantity > 100
)
SELECT 
    ti.i_item_id,
    ti.total_quantity,
    ti.total_net_paid,
    ti.sales_rank,
    COALESCE(AVG(cd.cd_purchase_estimate) FILTER (WHERE cd.cd_gender = 'F'), 0) AS avg_female_purchase_estimate,
    COALESCE(AVG(cd.cd_purchase_estimate) FILTER (WHERE cd.cd_gender = 'M'), 0) AS avg_male_purchase_estimate,
    CASE 
        WHEN ti.total_net_paid > 5000 THEN 'High Value'
        WHEN ti.total_net_paid BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    TopItems ti
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (
        SELECT c.c_current_cdemo_sk 
        FROM customer c 
        WHERE c.c_customer_sk = (
            SELECT MAX(c_customer_sk) 
            FROM customer 
            WHERE c_current_hdemo_sk IS NOT NULL
        )
    )
WHERE 
    ti.sales_rank <= 10
GROUP BY 
    ti.i_item_id,
    ti.total_quantity,
    ti.total_net_paid,
    ti.sales_rank
ORDER BY 
    ti.sales_rank;
