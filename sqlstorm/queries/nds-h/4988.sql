WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
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
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionPerformance AS (
    SELECT 
        n.n_name,
        r.r_name,
        SUM(ss.total_sales) AS region_total_sales,
        AVG(ss.order_count) AS avg_orders_per_supplier
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
PriceStats AS (
    SELECT 
        ps.ps_partkey,
        AVG(p.p_retailprice) AS avg_retail_price,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    rp.r_name,
    rp.n_name,
    rp.region_total_sales,
    rp.avg_orders_per_supplier,
    COALESCE(ps.avg_retail_price, 0) AS avg_retail_price,
    ps.supplier_count
FROM 
    RegionPerformance rp
LEFT JOIN 
    PriceStats ps ON ps.ps_partkey IN (
        SELECT 
            ps_partkey 
        FROM 
            partsupp 
        WHERE 
            ps_supplycost = (SELECT 
                                 MAX(ps_supplycost) 
                             FROM 
                                 partsupp)
    )
WHERE 
    rp.region_total_sales > (
        SELECT 
            AVG(region_total_sales) 
        FROM 
            RegionPerformance
    )
ORDER BY 
    rp.region_total_sales DESC;