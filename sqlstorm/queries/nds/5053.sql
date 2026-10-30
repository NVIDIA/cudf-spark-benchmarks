
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        si.i_category AS item_category,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        item si ON ws.ws_item_sk = si.i_item_sk
    JOIN 
        customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
    JOIN 
        customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cu.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, si.i_category, cd.cd_gender, hd.hd_income_band_sk
),
SalesRank AS (
    SELECT 
        ws_sold_date_sk,
        item_category,
        cd_gender,
        hd_income_band_sk,
        total_quantity,
        total_sales,
        total_discount,
        DENSE_RANK() OVER (PARTITION BY item_category, cd_gender, hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    sr.ws_sold_date_sk,
    sr.item_category,
    sr.cd_gender,
    sr.hd_income_band_sk,
    sr.total_quantity,
    sr.total_sales,
    sr.total_discount,
    sr.sales_rank
FROM 
    SalesRank sr
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.item_category,
    sr.cd_gender,
    sr.hd_income_band_sk,
    sr.total_sales DESC;
