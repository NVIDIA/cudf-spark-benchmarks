WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name IN ('Europe', 'Asia')
    GROUP BY 
        p.p_partkey, p.p_name
),
TopProducts AS (
    SELECT 
        p_partkey, 
        p_name, 
        total_sales 
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.p_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    AVG(o.o_totalprice) AS avg_order_price
FROM 
    TopProducts t 
JOIN 
    lineitem l ON t.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    t.p_name
ORDER BY 
    total_returned DESC, avg_order_price DESC;
