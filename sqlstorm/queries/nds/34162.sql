
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
return_data AS (
    SELECT 
        wr_return_quantity,
        wr_item_sk,
        SUM(wr_return_amt) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk, wr_return_quantity
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sum(s.total_spent), 0) AS total_sales,
        COALESCE(sum(r.total_returned), 0) AS total_returns
    FROM 
        item i
    LEFT JOIN 
        customer_stats s ON i.i_item_sk = s.c_customer_sk
    LEFT JOIN 
        return_data r ON i.i_item_sk = r.wr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    item_stats.i_item_desc,
    item_stats.total_sales,
    item_stats.total_returns,
    (item_stats.total_sales - item_stats.total_returns) AS net_sales,
    CASE
        WHEN item_stats.total_sales > 0 THEN (item_stats.total_returns * 1.0 / item_stats.total_sales) * 100
        ELSE NULL
    END AS return_percentage
FROM 
    item_stats
WHERE 
    (CASE 
         WHEN total_sales = 0 THEN 'No Sales' 
         WHEN total_sales - total_returns < 0 THEN 'Negative Net Sales' 
         ELSE 'Positive Net Sales' 
     END) = 'Positive Net Sales'
ORDER BY 
    net_sales DESC
LIMIT 10;
