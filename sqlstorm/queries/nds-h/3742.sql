WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), FinalResults AS (
    SELECT 
        ro.o_orderkey,
        CASE 
            WHEN ro.order_rank = 1 THEN 'Latest'
            WHEN ro.order_rank <= 3 THEN 'Recent'
            ELSE 'Older'
        END AS order_age,
        ro.total_lines,
        ro.total_revenue,
        fs.supplier_cost
    FROM 
        RankedOrders ro
    LEFT JOIN 
        FilteredSuppliers fs ON ro.o_orderkey = fs.s_suppkey
)

SELECT 
    fr.order_age,
    COUNT(*) AS order_count,
    AVG(fr.total_revenue) AS avg_revenue,
    SUM(fr.total_lines) AS total_lines
FROM 
    FinalResults fr
WHERE 
    fr.supplier_cost IS NOT NULL
GROUP BY 
    fr.order_age
ORDER BY 
    fr.order_age;
