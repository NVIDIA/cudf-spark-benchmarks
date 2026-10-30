WITH TotalSales AS (
    SELECT 
        l_partkey, 
        SUM(l_extendedprice * (1 - l_discount)) AS sales
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l_partkey
),
RankedSales AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        ts.sales,
        RANK() OVER (ORDER BY ts.sales DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
)
SELECT 
    r.r_name, 
    n.n_name, 
    s.s_name, 
    rs.p_name, 
    rs.p_brand, 
    rs.p_size, 
    rs.p_retailprice, 
    rs.sales, 
    rs.sales_rank
FROM 
    RankedSales rs
JOIN 
    partsupp ps ON rs.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    r.r_name, n.n_name, rs.sales DESC;
