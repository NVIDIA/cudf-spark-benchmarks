
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.region_name 
    FROM 
        RankedSuppliers s 
    WHERE 
        s.rank <= 5
), ProductSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l 
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
), SalesBySupplier AS (
    SELECT 
        ts.region_name,
        ps2.total_sales,
        COUNT(*) AS num_parts
    FROM 
        TopSuppliers ts 
    JOIN 
        lineitem l ON l.l_suppkey = ts.s_suppkey 
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey 
    JOIN 
        ProductSales ps2 ON ps2.p_partkey = ps.ps_partkey
    GROUP BY 
        ts.region_name, ps2.total_sales
)
SELECT 
    sb.region_name,
    SUM(sb.total_sales) AS total_revenue,
    AVG(sb.num_parts) AS avg_parts,
    COUNT(DISTINCT sb.region_name) AS unique_regions
FROM 
    SalesBySupplier sb
GROUP BY 
    sb.region_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
