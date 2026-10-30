WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS rnk
    FROM 
        SupplierSales
),
RegionSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(s.total_sales) AS region_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        TopSuppliers s ON n.n_nationkey = s.s_suppkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    r.region_name,
    r.nation_name,
    COALESCE(r.region_sales, 0) AS total_region_sales,
    t.rnk AS supplier_rank
FROM 
    RegionSales r
FULL OUTER JOIN 
    TopSuppliers t ON r.region_name = t.s_name
WHERE 
    t.total_sales IS NULL OR t.total_sales > 50000
ORDER BY 
    total_region_sales DESC, supplier_rank;
