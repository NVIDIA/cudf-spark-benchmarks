WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)

SELECT 
    r.region_name,
    rs.total_sales,
    rs.order_count,
    si.s_name,
    si.nation_name,
    si.s_acctbal,
    COALESCE(NULLIF(si.s_acctbal, 0), 0) AS adjusted_acctbal
FROM 
    RankedSales rs
LEFT JOIN 
    RegionalSales r ON rs.region_name = r.region_name
JOIN 
    SupplierInfo si ON si.s_acctbal > 10000
WHERE 
    rs.sales_rank <= 5 AND 
    (si.nation_name IS NOT NULL OR si.s_acctbal IS NOT NULL)
ORDER BY 
    rs.sales_rank;