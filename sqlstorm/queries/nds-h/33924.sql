
WITH  cust_order_cte AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
), 
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
), 
supplier_part_count AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(*) AS part_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    n.n_name,
    r.r_name,
    SUM(l.total_revenue) AS total_sales,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COALESCE(SUM(sp.part_count), 0) AS supplier_part_count
FROM 
    cust_order_cte co
LEFT JOIN 
    lineitem_summary l ON co.o_orderkey = l.l_orderkey
JOIN 
    customer c ON co.c_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier_part_count sp ON sp.ps_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_brand = 'Brand#54'
    )
WHERE 
    r.r_name LIKE 'Middle%'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_sales DESC;
