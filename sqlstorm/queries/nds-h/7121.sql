
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUM(l.l_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name, p.p_name
),
RegionAggregates AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_sales,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    ra.order_count,
    ra.total_sales,
    AVG(ra.total_quantity) AS avg_quantity_per_order
FROM 
    RegionAggregates ra
JOIN 
    region r ON r.r_name = ra.r_name
WHERE 
    ra.total_sales > 10000
GROUP BY 
    r.r_name, ra.order_count, ra.total_sales
ORDER BY 
    ra.total_sales DESC;
