WITH  CustomerCTE AS (
    SELECT c_custkey, c_name, c_acctbal, ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) as RowNum
    FROM customer
    WHERE c_acctbal > 0
),
SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) as RowNum
    FROM supplier
    WHERE s_acctbal > 0
),
TopCustomers AS (
    SELECT c_custkey, c_name, c_acctbal
    FROM CustomerCTE
    WHERE RowNum <= 5
),
TopSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal
    FROM SupplierCTE
    WHERE RowNum <= 5
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name AS Customer_Name,
    s.s_name AS Supplier_Name,
    COALESCE(ts.total_sales, 0) AS Total_Sales,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS Sales_Status
FROM TopCustomers c
FULL OUTER JOIN TopSuppliers s ON c.c_custkey = s.s_suppkey
LEFT JOIN TotalSales ts ON s.s_suppkey = ts.l_orderkey
WHERE c.c_custkey IS NOT NULL OR s.s_suppkey IS NOT NULL
ORDER BY Total_Sales DESC NULLS LAST;
