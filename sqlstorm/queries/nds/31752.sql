
WITH  price_trends AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_rec_start_date DESC) AS rn
    FROM item
    WHERE i_rec_start_date IS NOT NULL
), 
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
return_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
latest_shipping AS (
    SELECT 
        ws_item_sk,
        sm.sm_type
    FROM 
        web_sales AS ws
    INNER JOIN 
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), 
income_bracket AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics AS hd
    LEFT JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    SUM(ss.total_sales) AS total_sales,
    SUM(rs.total_returned_amount) AS total_returns,
    COUNT(DISTINCT lsm.sm_type) AS unique_shipping_modes,
    MAX(pt.i_current_price) AS latest_price
FROM 
    customer_info AS c
LEFT JOIN 
    sales_summary AS ss ON c.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    return_summary AS rs ON ss.ws_item_sk = rs.wr_item_sk
LEFT JOIN 
    latest_shipping AS lsm ON ss.ws_item_sk = lsm.ws_item_sk
LEFT JOIN 
    price_trends AS pt ON ss.ws_item_sk = pt.i_item_sk AND pt.rn = 1
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 100;
