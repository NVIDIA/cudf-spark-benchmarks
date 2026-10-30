
WITH AddressCounts AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerCounts AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    ac.address_count,
    cc.cd_gender,
    cc.customer_count,
    ds.d_date,
    ds.total_sales
FROM 
    AddressCounts ac
JOIN 
    CustomerCounts cc ON ac.ca_state = (CASE WHEN cc.cd_gender = 'F' THEN 'CA' ELSE 'NY' END)
JOIN 
    DailySales ds ON ds.total_sales > 1000
ORDER BY 
    ac.address_count DESC, 
    cc.customer_count DESC, 
    ds.total_sales DESC;
