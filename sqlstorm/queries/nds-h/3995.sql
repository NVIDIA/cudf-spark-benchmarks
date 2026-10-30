
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
        n.n_regionkey
),
RankedSales AS (
    SELECT 
        r.r_name,
        rs.total_sales,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        region r
    LEFT JOIN 
        RegionSales rs ON r.r_regionkey = rs.n_regionkey
)
SELECT 
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    rs.r_name AS region_name,
    rs.total_sales,
    rs.sales_rank
FROM 
    SupplierStats ss
LEFT JOIN 
    RankedSales rs ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE ps.ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp)
    )
WHERE 
    ss.unique_parts_supplied > 5
ORDER BY 
    ss.total_supply_cost DESC, rs.sales_rank
LIMIT 10;
