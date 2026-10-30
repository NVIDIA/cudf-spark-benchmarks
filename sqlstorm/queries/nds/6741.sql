
WITH RankedSales AS (
    SELECT 
        ws_supplier.w_warehouse_name,
        ws_ship_mode.sm_type,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_supplier.w_warehouse_name ORDER BY SUM(ws_ext_sales_price) DESC) AS sale_rank
    FROM 
        web_sales 
    JOIN 
        warehouse AS ws_supplier ON ws_supplier.w_warehouse_sk = web_sales.ws_warehouse_sk
    JOIN 
        ship_mode AS ws_ship_mode ON ws_ship_mode.sm_ship_mode_sk = web_sales.ws_ship_mode_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_supplier.w_warehouse_name, ws_ship_mode.sm_type
), 
HighestSales AS (
    SELECT 
        w_warehouse_name,
        sm_type,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sale_rank = 1
)
SELECT 
    hs.w_warehouse_name,
    hs.sm_type,
    hs.total_sales,
    COALESCE(ws_income.ib_lower_bound, 0) AS lower_income,
    COALESCE(ws_income.ib_upper_bound, 0) AS upper_income
FROM 
    HighestSales AS hs
LEFT JOIN 
    (SELECT 
        ib_income_band_sk, 
        ib_lower_bound, 
        ib_upper_bound 
     FROM 
        income_band) AS ws_income ON ws_income.ib_income_band_sk = (SELECT 
                                                                       hd_in.hd_income_band_sk 
                                                                     FROM 
                                                                       household_demographics AS hd_in
                                                                     JOIN 
                                                                       customer AS c
                                                                     ON 
                                                                       c.c_current_hdemo_sk = hd_in.hd_demo_sk
                                                                     WHERE 
                                                                       c.c_customer_id = 'customer_id_sample'
                                                                    LIMIT 1)
ORDER BY 
    hs.total_sales DESC;
