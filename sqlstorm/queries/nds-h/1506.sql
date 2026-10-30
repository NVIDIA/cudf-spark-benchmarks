WITH SupplierLineItems AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        nation.n_name AS nation_name,
        s.s_suppkey,
        s.s_name,
        sl.total_sales,
        sl.order_count
    FROM 
        SupplierLineItems sl
    JOIN 
        supplier s ON sl.s_suppkey = s.s_suppkey
    JOIN 
        nation ON s.s_nationkey = nation.n_nationkey
    WHERE 
        sl.rank <= 3
),
RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ts.total_sales) AS total_sales
    FROM 
        TopSuppliers ts
    JOIN 
        supplier s ON ts.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.region_name,
    r.total_sales,
    COALESCE(r.total_sales / NULLIF((SELECT SUM(total_sales) FROM RegionSales), 0), 0) * 100 AS sales_percentage,
    COUNT(*) FILTER (WHERE ts.order_count > 5) AS high_order_suppliers
FROM 
    RegionSales r
LEFT JOIN 
    TopSuppliers ts ON r.region_name = ts.nation_name
GROUP BY 
    r.region_name, r.total_sales
ORDER BY 
    r.total_sales DESC;