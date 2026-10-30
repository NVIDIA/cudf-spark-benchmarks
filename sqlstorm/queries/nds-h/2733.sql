WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey
        )
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        l.l_suppkey
),
SupplierSales AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        ts.total_sales,
        COALESCE(ts.total_sales, 0) AS calculated_sales,
        CASE 
            WHEN COALESCE(ts.total_sales, 0) = 0 THEN 'No Sales'
            ELSE 'Has Sales'
        END AS sales_status
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        TotalSales ts ON rs.s_suppkey = ts.l_suppkey
    WHERE 
        rs.rnk <= 5
)

SELECT 
    s.s_name,
    s.calculated_sales,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
FROM 
    SupplierSales s
JOIN 
    lineitem li ON s.s_suppkey = li.l_suppkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    supplier sp ON s.s_suppkey = sp.s_suppkey
JOIN 
    nation n ON sp.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    s.s_name, s.calculated_sales, r.r_name
HAVING 
    SUM(li.l_quantity) > 100
ORDER BY 
    s.calculated_sales DESC, order_count DESC;