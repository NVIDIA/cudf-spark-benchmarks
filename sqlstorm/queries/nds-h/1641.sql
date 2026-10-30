
WITH SupplierPart AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderLine AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        l.l_linestatus,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
Revenue AS (
    SELECT 
        part.p_partkey,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_revenue
    FROM 
        OrderLine ol
    JOIN 
        part part ON ol.l_partkey = part.p_partkey
    WHERE 
        ol.l_returnflag = 'N'
    GROUP BY 
        part.p_partkey
),
LessThanAvgRevenue AS (
    SELECT 
        AVG(total_revenue) AS avg_revenue
    FROM 
        Revenue
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    r.total_revenue,
    CASE 
        WHEN r.total_revenue < (SELECT avg_revenue FROM LessThanAvgRevenue) 
        THEN 'Below Average Revenue' 
        ELSE 'Above Average Revenue' 
    END AS revenue_status
FROM 
    SupplierPart sp
JOIN 
    Revenue r ON sp.p_partkey = r.p_partkey
WHERE 
    sp.rn = 1
ORDER BY 
    r.total_revenue DESC
LIMIT 10;
