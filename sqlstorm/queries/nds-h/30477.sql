WITH  regional_sales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate <= '1997-12-31'
    GROUP BY 
        r.r_regionkey, r.r_name
    
    UNION ALL
    
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) 
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
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
        AND l.l_returnflag = 'R'
    GROUP BY 
        r.r_regionkey, r.r_name
),
ranked_sales AS (
    SELECT 
        r.r_name,
        r.total_sales,
        RANK() OVER (ORDER BY r.total_sales DESC) AS sales_rank
    FROM 
        regional_sales r
)
SELECT 
    r.r_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    rs.sales_rank
FROM 
    (SELECT DISTINCT r_name FROM regional_sales) r
LEFT JOIN 
    ranked_sales rs ON r.r_name = rs.r_name
ORDER BY 
    total_sales DESC, r.r_name;