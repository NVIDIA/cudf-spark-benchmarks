WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        CONCAT(s.s_name, ' - ', n.n_name) AS full_supplier_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS sales_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedSales AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        ps.total_sales,
        ps.sales_count,
        RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM 
        PartSales ps
)
SELECT 
    sd.full_supplier_name,
    rs.p_name,
    rs.total_sales,
    rs.sales_count,
    rs.sales_rank
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    RankedSales rs ON ps.ps_partkey = rs.p_partkey
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_sales DESC, sd.nation_name, sd.region_name;
