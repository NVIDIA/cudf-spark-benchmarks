WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        r.r_name
), CustomerSegment AS (
    SELECT 
        c.c_mktsegment AS market_segment,
        SUM(o.o_totalprice) AS segment_sales,
        COUNT(DISTINCT o.o_orderkey) AS segment_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    rs.region_name,
    rs.total_sales,
    rs.total_orders,
    cs.market_segment,
    cs.segment_sales,
    cs.segment_orders
FROM 
    RegionSales rs
JOIN 
    CustomerSegment cs ON rs.total_sales > cs.segment_sales
ORDER BY 
    rs.total_sales DESC, cs.segment_sales DESC;
