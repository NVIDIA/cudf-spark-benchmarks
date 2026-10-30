
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank,
        p.p_type
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_totalprice > 10000 THEN 'High'
            WHEN o.o_totalprice BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS order_value_category
    FROM 
        orders o
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN h.order_value_category = 'High' THEN 1 ELSE 0 END) AS high_value_orders,
    SUM(CASE WHEN h.order_value_category = 'Medium' THEN 1 ELSE 0 END) AS medium_value_orders,
    SUM(CASE WHEN h.order_value_category = 'Low' THEN 1 ELSE 0 END) AS low_value_orders,
    COUNT(DISTINCT rs.s_suppkey) AS top_suppliers_count
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    HighValueOrders h ON c.c_custkey = h.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.p_type IN (SELECT DISTINCT p.p_type FROM part p)
WHERE 
    r.r_name LIKE 'North%'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_customers DESC, high_value_orders DESC;
