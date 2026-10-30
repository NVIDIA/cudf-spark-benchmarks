
WITH  sales_data AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_item_sk
),
customer_returns AS (
    SELECT 
        sr_store_sk,
        sr_item_sk, 
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk, sr_item_sk
),
combined_data AS (
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales
    FROM 
        sales_data s
    LEFT JOIN 
        customer_returns r ON s.ss_store_sk = r.sr_store_sk AND s.ss_item_sk = r.sr_item_sk
),
top_sales AS (
    SELECT 
        cs.ss_store_sk,
        cs.ss_item_sk,
        cs.total_sales,
        cs.total_returns,
        cs.net_sales,
        DENSE_RANK() OVER (ORDER BY cs.net_sales DESC) AS sales_rank
    FROM 
        combined_data cs
)

SELECT 
    st.s_store_id,
    it.i_item_id,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.total_returns, 0) AS total_returns,
    ts.net_sales,
    ts.sales_rank
FROM 
    store st
LEFT JOIN 
    top_sales ts ON st.s_store_sk = ts.ss_store_sk
LEFT JOIN 
    item it ON ts.ss_item_sk = it.i_item_sk
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.net_sales DESC, st.s_store_id, it.i_item_id;
