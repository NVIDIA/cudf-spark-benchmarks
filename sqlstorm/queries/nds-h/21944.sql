WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_cost >= (SELECT AVG(total_supply_cost) FROM SupplierDetails)
),
FinalSales AS (
    SELECT 
        rs.p_partkey,
        rs.p_name,
        rs.total_sales,
        COALESCE(ts.s_name, 'Unknown Supplier') AS supplier_name
    FROM 
        RankedSales rs
    LEFT JOIN 
        TopSuppliers ts ON rs.p_partkey = (SELECT ps.ps_partkey 
            FROM partsupp ps WHERE ps.ps_suppkey = 
                (SELECT l.l_suppkey 
                 FROM lineitem l 
                 WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
                 LIMIT 1) LIMIT 1)
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    fs.p_partkey,
    fs.p_name,
    fs.total_sales,
    fs.supplier_name,
    CASE 
        WHEN fs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_status
FROM 
    FinalSales fs
WHERE 
    fs.total_sales > (SELECT AVG(total_sales) FROM FinalSales)
UNION ALL
SELECT 
    -1 AS p_partkey,
    'Total' AS p_name,
    SUM(fs.total_sales) AS total_sales,
    NULL AS supplier_name,
    'Aggregate' AS sales_status
FROM 
    FinalSales fs
HAVING 
    SUM(fs.total_sales) IS NOT NULL
ORDER BY 
    p_partkey;
