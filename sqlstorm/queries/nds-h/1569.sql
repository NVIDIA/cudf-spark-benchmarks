WITH TotalSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        ps.ps_partkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
SizeTypeCounts AS (
    SELECT 
        p.p_size,
        p.p_type,
        COUNT(*) AS part_count,
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    GROUP BY 
        p.p_size, p.p_type
),
RankedSales AS (
    SELECT 
        ts.ps_partkey,
        ts.total_sales,
        ts.order_count,
        ROW_NUMBER() OVER (PARTITION BY stc.p_size ORDER BY ts.total_sales DESC) AS sales_rank,
        stc.avg_price
    FROM 
        TotalSales ts
    JOIN 
        SizeTypeCounts stc ON ts.ps_partkey = stc.p_size
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    rs.total_sales,
    rs.order_count,
    rs.sales_rank,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM 
    RankedSales rs
LEFT JOIN 
    SupplierDetails sd ON rs.ps_partkey = sd.s_suppkey
WHERE 
    rs.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
ORDER BY 
    sd.region_name, rs.total_sales DESC;
