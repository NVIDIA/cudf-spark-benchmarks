
WITH SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        SUM(cs_ext_tax) AS total_tax
    FROM 
        catalog_sales 
    GROUP BY 
        cs_item_sk
),
WarehouseInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalSales AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.total_tax,
        COALESCE(wi.total_inventory, 0) AS total_inventory,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        cr.total_return_count
    FROM 
        SalesData sd 
    LEFT JOIN 
        WarehouseInventory wi ON sd.cs_item_sk = wi.inv_item_sk
    LEFT JOIN 
        CustomerReturns cr ON sd.cs_item_sk = cr.sr_item_sk
)
SELECT 
    fs.cs_item_sk,
    fs.total_quantity,
    fs.total_sales,
    fs.total_discount,
    fs.total_tax,
    fs.total_inventory,
    fs.total_returned,
    fs.total_return_amount,
    fs.total_return_count,
    ROUND(fs.total_sales - fs.total_discount + fs.total_tax, 2) AS net_sales,
    CASE 
        WHEN fs.total_sales = 0 THEN 0
        ELSE ROUND(((fs.total_sales - fs.total_return_amount) / fs.total_sales) * 100, 2)
    END AS return_rate_perc
FROM 
    FinalSales fs
WHERE 
    fs.total_sales > 1000
ORDER BY 
    return_rate_perc DESC
LIMIT 10;
