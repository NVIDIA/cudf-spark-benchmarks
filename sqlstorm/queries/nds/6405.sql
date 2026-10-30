WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_month_seq,
        d.d_year
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 1999 AND 2001
    GROUP BY 
        w.w_warehouse_id, d.d_month_seq, d.d_year
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_returns AS cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, cr.cr_item_sk
),
FinalData AS (
    SELECT 
        sd.w_warehouse_id,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.total_returns,
        (sd.total_sales - sd.total_discount) AS net_sales
    FROM 
        SalesData AS sd
    LEFT JOIN 
        CustomerData AS cd ON sd.w_warehouse_id = cd.c_customer_id 
)
SELECT 
    w.w_warehouse_name,
    fd.cd_gender,
    fd.cd_marital_status,
    COUNT(fd.cd_credit_rating) AS credit_rating_count,
    AVG(fd.net_sales) AS avg_net_sales,
    SUM(fd.total_returns) AS total_returned_items
FROM 
    FinalData AS fd
JOIN 
    warehouse AS w ON fd.w_warehouse_id = w.w_warehouse_id
GROUP BY 
    w.w_warehouse_name, fd.cd_gender, fd.cd_marital_status
ORDER BY 
    w.w_warehouse_name, fd.cd_gender, fd.cd_marital_status;