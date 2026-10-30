WITH TotalSales AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' 
        AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        l.l_partkey
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_revenue, 0) AS total_revenue,
        COALESCE(sp.total_available, 0) AS total_available,
        ts.order_count,
        RANK() OVER (ORDER BY COALESCE(ts.total_revenue, 0) DESC) AS revenue_rank
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
    LEFT JOIN 
        SupplierPart sp ON p.p_partkey = sp.ps_partkey
),
FinalReport AS (
    SELECT 
        tp.p_partkey,
        tp.p_name,
        tp.total_revenue,
        tp.total_available,
        tp.order_count,
        tp.revenue_rank,
        CASE 
            WHEN tp.order_count > 10 THEN 'High Demand'
            WHEN tp.order_count BETWEEN 5 AND 10 THEN 'Moderate Demand'
            ELSE 'Low Demand'
        END AS demand_category
    FROM 
        TopParts tp
)
SELECT 
    r.r_name AS region_name,
    f.p_partkey,
    f.p_name,
    f.total_revenue,
    f.total_available,
    f.order_count,
    f.revenue_rank,
    f.demand_category
FROM 
    FinalReport f
JOIN 
    supplier s ON f.total_available > 0
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name IS NOT NULL 
ORDER BY 
    f.revenue_rank
LIMIT 100;