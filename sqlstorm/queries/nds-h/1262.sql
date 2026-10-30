
WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate <= '1996-12-31'
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales
    FROM supplier s
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.total_sales = (SELECT MAX(total_sales) FROM SupplierSales)
),
NationRegion AS (
    SELECT n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nr.n_name AS nation,
    nr.r_name AS region,
    COALESCE(TS.total_sales, 0) AS highest_supplier_sales
FROM 
    NationRegion nr
LEFT JOIN 
    TopSuppliers TS ON TS.s_suppkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_nationkey IS NOT NULL)
WHERE 
    nr.n_name IS NOT NULL
ORDER BY 
    nr.r_name, highest_supplier_sales DESC;
