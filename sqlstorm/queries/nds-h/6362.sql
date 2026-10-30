WITH AggregatedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),
RankedSales AS (
    SELECT 
        s.*,
        RANK() OVER (PARTITION BY s.n_name ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        AggregatedSales s
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    COUNT(rs.s_suppkey) AS supplier_count,
    SUM(rs.total_sales) AS total_sales,
    AVG(rs.total_sales) AS avg_sales
FROM 
    RankedSales rs
JOIN 
    nation ns ON rs.n_name = ns.n_name
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
WHERE 
    rs.sales_rank <= 5
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    r.r_name, total_sales DESC;