WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    ns.n_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(ts.total_sales) AS total_revenue,
    AVG(ss.total_supplycost) AS avg_supply_cost,
    MAX(ss.part_count) AS max_parts_per_supplier
FROM 
    nation ns
LEFT JOIN 
    customer c ON c.c_nationkey = ns.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    TotalSales ts ON o.o_orderkey = ts.l_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.part_count > 5  
WHERE 
    ns.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_name LIKE 'A%') 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;