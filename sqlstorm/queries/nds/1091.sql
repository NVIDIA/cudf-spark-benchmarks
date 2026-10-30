WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        CD.cd_gender,
        CD.cd_marital_status,
        CA.ca_state,
        D.d_year,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as rn
    FROM 
        web_sales ws
    JOIN 
        customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
    LEFT JOIN 
        customer_demographics CD ON cust.c_current_cdemo_sk = CD.cd_demo_sk
    LEFT JOIN 
        customer_address CA ON cust.c_current_addr_sk = CA.ca_address_sk
    JOIN 
        date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
    WHERE 
        ws.ws_sales_price > 0 
        AND D.d_year BETWEEN 1998 AND 2000
),
FilteredSales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT sd.ws_item_sk) AS item_count,
        MAX(sd.ws_sales_price) AS max_price,
        MIN(sd.ws_sales_price) AS min_price,
        CASE 
            WHEN sd.cd_gender = 'M' THEN 'Male'
            WHEN sd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_category
    FROM 
        SalesData sd
    WHERE 
        sd.rn = 1  
    GROUP BY 
        sd.ws_order_number, sd.cd_gender
),
FinalOutput AS (
    SELECT 
        fs.ws_order_number,
        fs.total_net_paid,
        fs.item_count,
        fs.max_price,
        fs.min_price,
        CASE 
            WHEN fs.total_net_paid > 1000 THEN 'High'
            WHEN fs.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_band,
        COUNT(*) OVER (PARTITION BY fs.gender_category) AS total_gender_count
    FROM 
        FilteredSales fs 
)
SELECT 
    fo.ws_order_number,
    fo.total_net_paid,
    fo.item_count,
    fo.max_price,
    fo.min_price,
    fo.sales_band,
    fo.total_gender_count,
    COALESCE(fo.total_gender_count * 1.0 / NULLIF(SUM(fo.total_gender_count) OVER (), 0), 0) AS percentage_of_gender
FROM 
    FinalOutput fo
WHERE 
    fo.total_net_paid IS NOT NULL
ORDER BY 
    fo.total_net_paid DESC;