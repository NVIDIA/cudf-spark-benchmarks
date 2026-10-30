
WITH RegionSales AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND l.l_shipdate > CURRENT_DATE - INTERVAL '6 month'
    GROUP BY 
        r.r_regionkey, r.r_name
), RankedSales AS (
    SELECT 
        r.*, 
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY r.total_sales DESC) AS sales_rank
    FROM 
        RegionSales r
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        AVG(s.s_acctbal) AS avg_balance,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), FinalReport AS (
    SELECT 
        rs.r_name, 
        rs.total_sales, 
        ss.avg_balance, 
        ss.total_avail_qty,
        rs.r_regionkey
    FROM 
        RankedSales rs
    FULL OUTER JOIN 
        SupplierStats ss ON rs.r_regionkey = ss.s_suppkey
)

SELECT 
    COALESCE(f.r_name, 'Unknown Region') AS region_name,
    COALESCE(f.total_sales, 0) AS total_sales_amount,
    COALESCE(f.avg_balance, (SELECT AVG(s_acctbal) FROM supplier)) AS average_balance,
    NULLIF(f.total_avail_qty, 0) AS available_quantity,
    CONCAT('Region: ', COALESCE(f.r_name, 'No Name')) AS formatted_region
FROM 
    FinalReport f
WHERE 
    f.total_sales > 100000 OR f.avg_balance IS NULL
ORDER BY 
    f.total_sales DESC;
