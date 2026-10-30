WITH RankedSales AS (
    SELECT 
        ps.ps_partkey, 
        p.p_name, 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name, s.s_suppkey, s.s_name
),
FilteredSales AS (
    SELECT 
        r.r_name, 
        SUM(rs.total_sales) AS total_sales_per_region
    FROM 
        RankedSales rs
    LEFT JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank_sales = 1
        AND r.r_name IS NOT NULL
    GROUP BY 
        r.r_name
),
OrderStatistics AS (
    SELECT 
        o.o_orderstatus, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_extendedprice) AS avg_order_value,
        SUM(CASE 
                WHEN o.o_orderstatus = 'F' THEN 1 
                ELSE 0 
            END) AS completed_orders,
        SUM(NULLIF(o.o_totalprice, 0)) AS total_price_non_zero 
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderstatus
)
SELECT 
    COALESCE(fs.r_name, 'Unknown Region') AS region_name,
    fs.total_sales_per_region,
    os.o_orderstatus,
    os.order_count,
    os.avg_order_value,
    os.completed_orders,
    os.total_price_non_zero
FROM 
    FilteredSales fs
FULL OUTER JOIN 
    OrderStatistics os ON os.o_orderstatus = CASE 
                                                 WHEN fs.total_sales_per_region > 10000 THEN 'C' 
                                                 ELSE 'F' 
                                             END
ORDER BY 
    fs.total_sales_per_region DESC, 
    os.order_count DESC;