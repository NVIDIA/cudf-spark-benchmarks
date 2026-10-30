
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS row_num
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), 
item_returns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
store_data AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_net_paid) AS store_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS web_sales_quantity,
    COALESCE(sd.total_sales, 0) AS web_sales_total,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amt, 0) AS total_return_amount,
    COALESCE(st.store_quantity, 0) AS store_sales_quantity,
    COALESCE(st.store_sales, 0) AS store_sales_total
FROM 
    item i
LEFT JOIN 
    sales_data sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    item_returns rd ON i.i_item_sk = rd.wr_item_sk
LEFT JOIN 
    store_data st ON i.i_item_sk = st.ss_item_sk
WHERE 
    sd.row_num <= 5 OR sd.ws_item_sk IS NULL
ORDER BY 
    web_sales_total DESC, 
    total_returns DESC
LIMIT 10;
