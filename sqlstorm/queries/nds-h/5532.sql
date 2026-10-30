WITH NationSales AS (
    SELECT 
        n.n_name AS nation,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_name
),
PartDetails AS (
    SELECT 
        p.p_name AS part_name,
        p.p_brand AS part_brand,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_name, p.p_brand
),
CombinedMetrics AS (
    SELECT 
        ns.nation,
        ps.part_name,
        ps.part_brand,
        ps.total_quantity,
        ps.avg_price,
        ns.total_sales
    FROM 
        NationSales ns
    JOIN 
        PartDetails ps ON ns.nation = 'NETHERLANDS'
)
SELECT 
    nation,
    part_name,
    part_brand,
    total_quantity,
    avg_price,
    total_sales,
    total_sales / NULLIF(total_quantity, 0) AS sales_per_quantity
FROM 
    CombinedMetrics
ORDER BY 
    total_sales DESC, total_quantity DESC
LIMIT 10;
