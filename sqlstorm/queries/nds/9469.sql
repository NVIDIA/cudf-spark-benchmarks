
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_ext_tax) AS total_ext_tax
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateData AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_dow
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2021
),
ItemData AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= '2021-12-31' 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= '2021-01-01')
)
SELECT 
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    c.cd_gender,
    c.cd_education_status,
    c.cd_marital_status,
    item.i_item_desc,
    SUM(sd.total_quantity) AS sales_quantity,
    SUM(sd.total_net_paid) AS total_sales,
    SUM(sd.total_ext_tax) AS total_tax
FROM 
    SalesData sd
JOIN 
    DateData d ON sd.ws_sold_date_sk = d.d_date_sk
JOIN 
    CustomerData c ON sd.ws_item_sk IN (SELECT i.i_item_sk FROM ItemData i)
JOIN 
    ItemData item ON sd.ws_item_sk = item.i_item_sk
GROUP BY 
    d.d_year, d.d_month_seq, d.d_week_seq, c.cd_gender, 
    c.cd_education_status, c.cd_marital_status, item.i_item_desc
ORDER BY 
    d.d_year ASC, 
    d.d_month_seq ASC, 
    sales_quantity DESC;
