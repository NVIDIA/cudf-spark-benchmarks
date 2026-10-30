
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, i.i_item_desc
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_amount_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    sd.ws_sold_date_sk,
    sd.i_item_desc,
    cd.cd_gender,
    cd.hd_income_band_sk,
    sd.total_quantity,
    sd.total_sales,
    cd.total_orders,
    cd.total_amount_spent
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON sd.ws_item_sk = cd.c_customer_sk
WHERE 
    sd.sales_rank <= 5 
    AND (cd.hd_income_band_sk IS NULL OR cd.hd_income_band_sk BETWEEN 1 AND 5)
ORDER BY 
    sd.total_sales DESC, 
    cd.total_amount_spent ASC;
