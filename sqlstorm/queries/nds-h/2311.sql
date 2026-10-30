
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation,
    COALESCE(SUM(ros.total_order_value), 0) AS total_order_value,
    COUNT(DISTINCT ros.c_custkey) AS customer_count,
    MIN(rs.total_supply_value) AS min_supply_value,
    MAX(rs.total_supply_value) AS max_supply_value,
    AVG(rs.total_supply_value) AS avg_supply_value
FROM 
    nation n
LEFT JOIN 
    CustomerOrderDetails ros ON n.n_nationkey = ros.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey 
WHERE 
    rs.rank <= 5
GROUP BY 
    n.n_name
ORDER BY 
    nation;
