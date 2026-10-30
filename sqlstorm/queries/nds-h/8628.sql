WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
),
RankedSales AS (
    SELECT 
        ts.p_partkey,
        ts.revenue,
        RANK() OVER (ORDER BY ts.revenue DESC) AS sales_rank
    FROM 
        TotalSales ts
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name as supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    rs.sales_rank,
    rs.revenue,
    si.s_name,
    si.supplier_nation
FROM 
    RankedSales rs
JOIN 
    partsupp ps ON rs.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.revenue DESC, si.s_name ASC;
