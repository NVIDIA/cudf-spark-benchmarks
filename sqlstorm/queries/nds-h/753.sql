
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate > '1997-01-01'
    GROUP BY 
        r.r_name
),
SupplierCount AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
FilteredSales AS (
    SELECT 
        rs.region_name, 
        rs.total_sales, 
        sc.supplier_count,
        ROW_NUMBER() OVER (ORDER BY rs.total_sales DESC) AS rank
    FROM 
        RegionalSales rs
        JOIN SupplierCount sc ON rs.region_name = sc.n_name
)
SELECT 
    fs.region_name, 
    fs.total_sales, 
    fs.supplier_count
FROM 
    FilteredSales fs
WHERE 
    fs.total_sales > (SELECT AVG(total_sales) FROM RegionalSales)
ORDER BY 
    fs.total_sales DESC
LIMIT 10;
