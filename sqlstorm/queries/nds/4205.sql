
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS customer_total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.customer_total_sales,
        DENSE_RANK() OVER (ORDER BY cs.customer_total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
PopularItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    ci.c_customer_sk,
    ci.customer_total_sales,
    pi.ws_item_sk,
    pi.total_quantity,
    pi.total_sales
FROM 
    RankedSales ci
LEFT JOIN 
    PopularItems pi ON ci.sales_rank = pi.total_quantity
WHERE 
    ci.customer_total_sales > (SELECT AVG(customer_total_sales) FROM CustomerSales) 
    AND (
        ci.customer_total_sales IS NOT NULL OR 
        pi.total_quantity IS NOT NULL
    )
ORDER BY 
    ci.customer_total_sales DESC, pi.total_sales DESC;
