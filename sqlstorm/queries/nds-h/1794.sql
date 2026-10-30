WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        tv.total_value
    FROM 
        TotalOrderValue tv
    JOIN 
        orders o ON tv.o_orderkey = o.o_orderkey
    WHERE 
        tv.total_value > 10000
),
SupplierOrderInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ho.o_orderkey,
        ho.total_value
    FROM 
        RankedSuppliers s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        HighValueOrders ho ON l.l_orderkey = ho.o_orderkey
)

SELECT 
    r.r_name,
    COUNT(DISTINCT soi.o_orderkey) AS total_high_value_orders,
    AVG(soi.total_value) AS avg_order_value
FROM 
    SupplierOrderInfo soi
JOIN 
    supplier s ON soi.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    soi.total_value IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT soi.o_orderkey) > 0
ORDER BY 
    avg_order_value DESC;
