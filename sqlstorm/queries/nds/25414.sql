
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        CASE 
            WHEN ca_zip LIKE '_____' THEN ca_zip
            ELSE 'Invalid Zip Code'
        END AS validated_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.validated_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
DateSales AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date_sk, d.d_date
),
SalesRanked AS (
    SELECT
        cs.c_customer_sk,
        ds.total_sales,
        RANK() OVER (PARTITION BY cs.c_customer_sk ORDER BY ds.total_sales DESC) AS sales_rank
    FROM 
        CustomerDetails cs
    JOIN 
        DateSales ds ON ds.d_date_sk = cs.c_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    dr.total_sales,
    dr.sales_rank
FROM 
    CustomerDetails cd
JOIN 
    SalesRanked dr ON cd.c_customer_sk = dr.c_customer_sk
WHERE 
    dr.sales_rank = 1
ORDER BY 
    cd.c_last_name, cd.c_first_name;
