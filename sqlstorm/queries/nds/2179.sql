
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, ss.ss_customer_sk, ss.ss_sold_date_sk
),
TopSales AS (
    SELECT 
        r.c_customer_id,
        r.total_quantity,
        r.total_sales,
        r.sales_rank
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
CustomerInfo AS (
    SELECT 
        t.c_customer_id,
        t.total_quantity,
        t.total_sales,
        a.ca_city,
        a.ca_state,
        a.ca_zip
    FROM 
        TopSales t
    LEFT JOIN 
        AddressDetails a ON t.c_customer_id = a.ca_address_id
)
SELECT 
    ci.c_customer_id,
    ci.total_quantity,
    ci.total_sales,
    COALESCE(ci.ca_city, 'Unknown') AS city,
    COALESCE(ci.ca_state, 'Unknown') AS state,
    COALESCE(ci.ca_zip, '00000') AS zip,
    CAST('2002-10-01' AS DATE) AS report_date
FROM 
    CustomerInfo ci
ORDER BY 
    ci.total_sales DESC
LIMIT 50;
