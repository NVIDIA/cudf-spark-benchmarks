
WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
),
income_summary AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics h
    LEFT JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        h.hd_income_band_sk
),
return_statistics AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_sales, 0) AS web_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_returned_amount, 0.00) AS total_returned_amount,
    i.i_current_price,
    CASE 
        WHEN s.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular'
    END AS sales_category,
    SUM(CASE WHEN s.total_sales > 0 THEN 1 ELSE 0 END) AS is_positive_total_sales
FROM 
    item i
LEFT JOIN 
    (SELECT 
         ws_item_sk,
         total_sales,
         sales_rank
     FROM 
         sales_cte 
     WHERE 
         sales_rank <= 10) s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    return_statistics r ON i.i_item_sk = r.sr_item_sk
LEFT JOIN 
    income_summary inc ON inc.hd_income_band_sk = (SELECT hd_income_band_sk FROM household_demographics ORDER BY hd_buy_potential DESC LIMIT 1)
GROUP BY 
    i.i_item_id, i.i_item_desc, s.total_sales, r.total_returns, r.total_returned_amount, i.i_current_price, s.sales_rank
ORDER BY 
    web_sales DESC
LIMIT 100;
