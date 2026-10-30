
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_mktsegment
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ps.ps_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_container LIKE '%BOX%' AND 
        ps.ps_availqty > 100
)
SELECT 
    r.c_mktsegment,
    r.c_name,
    r.total_revenue,
    p.p_name,
    p.supplier_name,
    p.ps_supplycost,
    p.ps_availqty,
    p.ps_comment,
    CONCAT('Total Revenue for ', r.c_name, ' in segment ', r.c_mktsegment, ' is: ', CAST(r.total_revenue AS VARCHAR(20))) AS revenue_message
FROM 
    RankedOrders r
JOIN 
    SupplierPartDetails p ON r.o_orderkey = p.p_partkey
WHERE 
    r.revenue_rank <= 5 
ORDER BY 
    r.c_mktsegment, r.total_revenue DESC;
