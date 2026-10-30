
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
SalesData AS (
    SELECT 
        d.d_date,
        ti.ws_item_sk,
        ti.total_sales,
        i.i_item_desc,
        i.i_current_price
    FROM 
        TopSellingItems ti
    JOIN 
        date_dim d ON ti.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ti.ws_item_sk = i.i_item_sk
),
DemographicSales AS (
    SELECT 
        cd.cd_gender,
        SUM(sd.total_sales) AS total_sales_by_gender
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.ws_item_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    ds.total_sales_by_gender,
    ROUND(ds.total_sales_by_gender / SUM(ds.total_sales_by_gender) OVER () * 100, 2) AS percentage_of_total
FROM 
    DemographicSales ds
JOIN 
    customer_demographics cd ON ds.cd_gender = cd.cd_gender
ORDER BY 
    ds.total_sales_by_gender DESC;
