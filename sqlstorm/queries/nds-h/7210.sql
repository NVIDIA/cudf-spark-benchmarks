WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supplier_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT 
        r.region_name,
        ss.supplier_name,
        ss.total_supplier_sales,
        RANK() OVER (PARTITION BY r.region_name ORDER BY ss.total_supplier_sales DESC) AS sales_rank
    FROM 
        RegionalSales r
    JOIN 
        SupplierSales ss ON r.total_sales > 0
)
SELECT 
    region_name,
    supplier_name,
    total_supplier_sales,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 3
ORDER BY 
    region_name, sales_rank;